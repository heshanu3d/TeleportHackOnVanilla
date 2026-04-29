"""Toggle services for memory-patch features (anti-jump, autoloot, lua-unlock,
patch-loot, speed)."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Sequence

from teleport_hack.domain.versions import GameVersion
from teleport_hack.infrastructure.memory.backend import MemoryBackend


class FeatureName(str, Enum):
    ANTI_JUMP = "anti_jump"
    AUTOLOOT = "autoloot"
    PATCH_LOOT = "patch_loot"
    LUA_UNLOCK = "lua_unlock"


@dataclass(frozen=True)
class _BytePatch:
    """Pair of byte sequences representing the OFF and ON states of a patch."""

    off: tuple[tuple[int, int], ...]  # (offset, byte) pairs forming the OFF state
    on: tuple[tuple[int, int], ...]  # ... and the ON state


class FeatureService:
    """Apply / revert reversible memory patches.

    Each feature has two well-known byte patterns; the service detects the
    current state and toggles to the other. Unknown states raise
    :class:`ValueError` (mirrors the original ``print("set ... error")``).
    """

    def __init__(self, backend: MemoryBackend, version: GameVersion) -> None:
        self._backend = backend
        self._v = version

    # ---------------------------------------------------------- AntiJump

    def toggle_anti_jump(self) -> bool:
        """Returns ``True`` if anti-jump is now ON."""
        addr = self._v.anti_jump
        self._require(addr, "anti_jump")
        val = self._backend.read_byte(addr)
        if val == 0x75:
            self._backend.write_byte(addr, 0xEB)
            self._set_jump_gravity(0.0)
            return True
        if val == 0xEB:
            self._backend.write_byte(addr, 0x75)
            self._set_jump_gravity(-7.0)
            return False
        raise ValueError(f"Unknown anti-jump state: 0x{val:02X}")

    def _set_jump_gravity(self, value: float) -> None:
        if self._v.jump_gravity:
            self._backend.write_float(self._v.jump_gravity, value)

    # ---------------------------------------------------------- Autoloot

    def toggle_autoloot(self) -> bool:
        addr = self._v.autoloot_2
        self._require(addr, "autoloot")
        b0 = self._backend.read_byte(addr)
        b1 = self._backend.read_byte(addr + 1)
        if (b0, b1) == (0x74, 0x10):
            self._backend.write_byte(addr, 0x90)
            self._backend.write_byte(addr + 1, 0x90)
            return True
        if (b0, b1) == (0x90, 0x90):
            self._backend.write_byte(addr, 0x74)
            self._backend.write_byte(addr + 1, 0x10)
            return False
        raise ValueError(f"Unknown autoloot state: 0x{b0:02X}{b1:02X}")

    # --------------------------------------------------------- PatchLoot

    def toggle_patch_loot(self) -> bool:
        a, b, c = self._v.patch_loot, self._v.patch_loot2, self._v.patch_lootslot
        self._require(a and b and c, "patch_loot")
        v0 = self._backend.read_byte(a)
        v1 = self._backend.read_byte(b)
        v2 = self._backend.read_byte(c)
        if (v0, v1, v2) == (0x72, 0x72, 0x01):
            self._backend.write_byte(a, 0xEB)
            self._backend.write_byte(b, 0xEB)
            self._backend.write_byte(c, 0x00)
            return True
        if (v0, v1, v2) == (0xEB, 0xEB, 0x00):
            self._backend.write_byte(a, 0x72)
            self._backend.write_byte(b, 0x72)
            self._backend.write_byte(c, 0x01)
            return False
        raise ValueError("Unknown patch_loot state")

    # ---------------------------------------------------------- LuaUnlock

    _LUA_OFF: Sequence[int] = (0x56, 0x8B, 0xF1, 0x0F, 0x84, 0xB1)
    _LUA_ON: Sequence[int] = (0xB8, 0x01, 0x00, 0x00, 0x00, 0xC3)

    def toggle_lua_unlock(self) -> bool:
        addr = self._v.lua_unlock
        self._require(addr, "lua_unlock")
        current = tuple(self._backend.read_byte(addr + i) for i in range(6))
        if current == tuple(self._LUA_OFF):
            for i, b in enumerate(self._LUA_ON):
                self._backend.write_byte(addr + i, b)
            return True
        if current == tuple(self._LUA_ON):
            for i, b in enumerate(self._LUA_OFF):
                self._backend.write_byte(addr + i, b)
            return False
        raise ValueError("Unknown lua_unlock state")

    # ----------------------------------------------------------- Speed

    def set_speed(self, speed: float) -> None:
        if not self._v.supports_speed:
            return
        # Only meaningful on pointer-chain clients (3.3.5).
        pb1 = self._backend.read_pointer(self._v.static_player)
        pb2 = self._backend.read_pointer(pb1 + self._v.pb_pointer1)
        base = self._backend.read_pointer(pb2 + self._v.pb_pointer2)
        self._backend.write_float(base + self._v.speed_global, float(speed))

    # ------------------------------------------------------------ helpers

    @staticmethod
    def _require(condition, feature: str) -> None:
        if not condition:
            raise ValueError(f"Feature {feature!r} is not supported on this client.")
