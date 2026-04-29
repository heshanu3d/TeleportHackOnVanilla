"""High-level teleport service.

Centralises:
* address resolution (pointer chain for 3.3.5, multi-level offsets for 1.12.x)
* coordinate-axis swapping (1.12.x stores Y/X swapped relative to UI input)
* step-by-step teleporting (smooth movement)

The service is given a :class:`MemoryBackend` and a :class:`GameVersion` and
exposes a tiny vocabulary: read / write / step.
"""

from __future__ import annotations

import math
import time
from dataclasses import dataclass
from typing import Optional

from teleport_hack.domain.models import Position
from teleport_hack.domain.versions import GameVersion
from teleport_hack.infrastructure.memory.backend import MemoryBackend


@dataclass
class StepConfig:
    """Tuning knobs for :meth:`TeleportService.teleport_step`."""

    distance_per_step: float = 10.0
    sleep_between_steps: float = 0.04


class TeleportService:
    def __init__(self, backend: MemoryBackend, version: GameVersion) -> None:
        self._backend = backend
        self._v = version

    # ---------------------------------------------------------- read / write

    def read_position(self) -> Position:
        if self._v.is_pointer_chain:
            base = self._resolve_player_base()
            x = self._backend.read_float(base + self._v.pos_x)
            y = self._backend.read_float(base + self._v.pos_y)
            z = self._backend.read_float(base + self._v.pos_z)
            return Position(x, y, z)

        x = self._backend.read_float(self._v.curr_pos_x)
        y = self._backend.read_float(self._v.curr_pos_y)
        z = self._backend.read_float(self._v.curr_pos_z)
        # On 1.12.1 / 1.12.3 the engine reports Y as X internally; the UI
        # always wants logical (x, y, z) order so we swap on read & write.
        if self._v.name.startswith("1.12"):
            return Position(y, x, z)
        return Position(x, y, z)

    def write_position(self, pos: Position) -> None:
        if self._v.is_pointer_chain:
            base = self._resolve_player_base()
            # 3.3.5 also has axis swap when *writing*
            self._backend.write_float(base + self._v.pos_x, pos.y)
            self._backend.write_float(base + self._v.pos_y, pos.x)
            self._backend.write_float(base + self._v.pos_z, pos.z)
            return

        addrs = self._resolve_vanilla_write_addresses()
        # The vanilla layout writes (x_target=engine_x, y_target=engine_y).
        # Original code passes WritePosition($y, $x, $z) from the UI layer.
        self._backend.write_float(addrs[0], pos.y)
        self._backend.write_float(addrs[1], pos.x)
        self._backend.write_float(addrs[2], pos.z)

    # ---------------------------------------------------------- step-by-step

    def teleport_step(
        self,
        target: Position,
        config: Optional[StepConfig] = None,
        sleeper=time.sleep,
    ) -> int:
        """Walk to ``target`` in equal increments, return number of steps used."""
        cfg = config or StepConfig()
        current = self.read_position()
        distance = current.distance_to(target)
        steps = max(1, math.floor(distance / max(cfg.distance_per_step, 1e-6)) + 1)

        dx = (target.x - current.x) / steps
        dy = (target.y - current.y) / steps
        dz = (target.z - current.z) / steps

        cursor = current
        for _ in range(steps):
            cursor = Position(cursor.x + dx, cursor.y + dy, cursor.z + dz)
            self.write_position(cursor)
            if cfg.sleep_between_steps > 0:
                sleeper(cfg.sleep_between_steps)
        return steps

    def read_map_id(self) -> Optional[int]:
        if not self._v.map_id:
            return None
        return self._backend.read_uint32(self._v.map_id)

    # ----------------------------------------------------------- private

    def _resolve_player_base(self) -> int:
        pb1 = self._backend.read_pointer(self._v.static_player)
        pb2 = self._backend.read_pointer(pb1 + self._v.pb_pointer1)
        return self._backend.read_pointer(pb2 + self._v.pb_pointer2)

    def _resolve_vanilla_write_addresses(self) -> tuple[int, int, int]:
        """Walk the multi-level offset chain used by 1.12.x clients."""
        ax = ay = az = self._v.static_player
        for ox, oy, oz in zip(
            self._v.dst_x_offsets,
            self._v.dst_y_offsets,
            self._v.dst_z_offsets,
        ):
            ax = self._backend.read_pointer(ax) + ox
            ay = self._backend.read_pointer(ay) + oy
            az = self._backend.read_pointer(az) + oz
        return ax, ay, az
