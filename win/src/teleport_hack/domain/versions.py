"""Per-WoW-client memory layout descriptors.

These constants are lifted from the ``main*.au3`` entry points in the original
project. Putting them in plain dataclasses lets us select a profile at runtime
and keeps memory addresses out of the business logic.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Mapping, Optional


@dataclass(frozen=True)
class GameVersion:
    """Static memory layout for a particular WoW client build."""

    name: str
    executable: str  # e.g. "WoW.exe"
    window_class: str = "GxWindowClassD3d"

    # Static addresses
    static_player: int = 0
    curr_pos_x: int = 0
    curr_pos_y: int = 0
    curr_pos_z: int = 0
    anti_jump: int = 0
    jump_gravity: int = 0
    player_name: int = 0
    map_id: int = 0

    # Pointer offsets (only used by 3.3.5)
    pb_pointer1: int = 0
    pb_pointer2: int = 0
    pos_x: int = 0
    pos_y: int = 0
    pos_z: int = 0
    pos_r: int = 0
    speed_global: int = 0

    # Multi-level write offsets (vanilla only)
    dst_x_offsets: tuple[int, ...] = ()
    dst_y_offsets: tuple[int, ...] = ()
    dst_z_offsets: tuple[int, ...] = ()

    # Code-patch addresses
    autoloot_2: int = 0
    patch_loot: int = 0
    patch_loot2: int = 0
    patch_lootslot: int = 0
    lua_unlock: int = 0

    @property
    def supports_speed(self) -> bool:
        return self.speed_global != 0

    @property
    def supports_anti_jump(self) -> bool:
        return self.anti_jump != 0

    @property
    def supports_autoloot(self) -> bool:
        return self.autoloot_2 != 0

    @property
    def is_pointer_chain(self) -> bool:
        """True for clients that walk a pointer chain (e.g. 3.3.5)."""
        return self.pb_pointer1 != 0 or self.pb_pointer2 != 0


# --- Concrete profiles, see main1.12.1.au3 / main1.12.3.au3 / main3.3.5.au3 ---

_VANILLA_OFFSETS_X = (0x88, 0x28, 0x708, 0xC, 0x2A8)
_VANILLA_OFFSETS_Y = (0x88, 0x28, 0x6B4, 0x3C, 0x2C8)
_VANILLA_OFFSETS_Z = (0x88, 0x28, 0x7C8, 0x1A4, 0x54)


VERSION_1_12_1 = GameVersion(
    name="1.12.1",
    executable="WoW.exe",
    static_player=0x00C7BCD4,
    curr_pos_x=0x00C7B548,
    curr_pos_y=0x00C7B544,
    curr_pos_z=0x00C7B54C,
    anti_jump=0x7C625F,
    jump_gravity=0x7C6272,
    player_name=0xC27D88,
    autoloot_2=0x4C1ECF,
    patch_loot=0x4C21C0,
    patch_loot2=0x4C28FF,
    patch_lootslot=0x4C2E94,
    lua_unlock=0x494A57,
    dst_x_offsets=_VANILLA_OFFSETS_X,
    dst_y_offsets=_VANILLA_OFFSETS_Y,
    dst_z_offsets=_VANILLA_OFFSETS_Z,
)

VERSION_1_12_3 = GameVersion(
    name="1.12.3",
    executable="WoW.exe",
    static_player=0x00C803F4,
    curr_pos_x=0x00C7FC64,
    curr_pos_y=0x00C7FC68,
    curr_pos_z=0x00C7FC6C,
    anti_jump=0x7C973F,
    jump_gravity=0x7C9752,
    player_name=0xC2C430,
    autoloot_2=0x4C2CBF,
    patch_loot=0x4C2FB0,
    patch_loot2=0x4C36EF,
    patch_lootslot=0x4C3C96,
    lua_unlock=0x495847,
    dst_x_offsets=_VANILLA_OFFSETS_X,
    dst_y_offsets=_VANILLA_OFFSETS_Y,
    dst_z_offsets=_VANILLA_OFFSETS_Z,
)

VERSION_3_3_5 = GameVersion(
    name="3.3.5",
    executable="WoW.exe",
    static_player=0x00CD87A8,
    player_name=0xC79D10 + 8,
    map_id=0xAB63BC,
    pb_pointer1=0x34,
    pb_pointer2=0x24,
    pos_x=0x798,
    pos_y=0x79C,
    pos_z=0x7A0,
    pos_r=0x7A8,
    speed_global=0x814,
)


VERSIONS: Mapping[str, GameVersion] = {
    "1.12.1": VERSION_1_12_1,
    "1.12.3": VERSION_1_12_3,
    "3.3.5": VERSION_3_3_5,
}


def get_version(name: str) -> Optional[GameVersion]:
    return VERSIONS.get(name)
