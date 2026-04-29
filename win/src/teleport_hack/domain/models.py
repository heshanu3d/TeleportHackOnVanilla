"""Core value objects and entities for the teleport-hack domain.

The objects here are pure data containers / value objects with light helper
methods. They have no I/O or platform dependencies and are trivially
unit-testable.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Iterable, Iterator, List, Sequence

ALL_CATEGORY = "所有"  # special pseudo-category meaning "everything"
OTHER_CATEGORY = "其他"  # fallback when description has no dash


@dataclass(frozen=True)
class Position:
    """A 3D world position. Stored in the canonical (x, y, z) order."""

    x: float
    y: float
    z: float

    def as_tuple(self) -> tuple[float, float, float]:
        return (self.x, self.y, self.z)

    def distance_to(self, other: "Position") -> float:
        dx, dy, dz = self.x - other.x, self.y - other.y, self.z - other.z
        return (dx * dx + dy * dy + dz * dz) ** 0.5

    @classmethod
    def from_strings(cls, x: str, y: str, z: str) -> "Position":
        return cls(float(x), float(y), float(z))


@dataclass(frozen=True)
class TeleportPoint:
    """A named teleport entry stored in the favourites file."""

    description: str
    position: Position

    @property
    def category(self) -> str:
        """Derive the category from the description.

        Mirrors the AutoIt rule: take the substring before the first ``-``.
        If there is no dash, the point lives in :data:`OTHER_CATEGORY`.
        """
        head, sep, _ = self.description.partition("-")
        return head if sep else OTHER_CATEGORY

    def to_serialized_fields(self) -> tuple[str, str, str, str]:
        return (
            self.description,
            _format_float(self.position.x),
            _format_float(self.position.y),
            _format_float(self.position.z),
        )


def _format_float(value: float) -> str:
    """Format like the AutoIt source does (drop redundant trailing zeros)."""
    if value == int(value):
        return str(int(value))
    formatted = f"{value:.6f}".rstrip("0").rstrip(".")
    return formatted or "0"


@dataclass
class Category:
    """A named bucket of teleport points preserving insertion order."""

    name: str
    points: List[TeleportPoint] = field(default_factory=list)

    def add(self, point: TeleportPoint) -> None:
        self.points.append(point)

    def insert(self, index: int, point: TeleportPoint) -> None:
        self.points.insert(index, point)

    def remove_at(self, index: int) -> TeleportPoint:
        return self.points.pop(index)

    def replace_at(self, index: int, point: TeleportPoint) -> None:
        self.points[index] = point

    def __iter__(self) -> Iterator[TeleportPoint]:
        return iter(self.points)

    def __len__(self) -> int:
        return len(self.points)

    @classmethod
    def from_points(cls, name: str, points: Iterable[TeleportPoint]) -> "Category":
        return cls(name=name, points=list(points))


class Modifier(str, Enum):
    """Hotkey modifier keys, encoded with the AutoIt ``+^!`` prefix scheme."""

    SHIFT = "+"
    CTRL = "^"
    ALT = "!"

    @classmethod
    def parse_prefix(cls, raw: str) -> tuple[frozenset["Modifier"], str]:
        """Split a string like ``"^!1"`` into ({CTRL, ALT}, "1")."""
        mods: set[Modifier] = set()
        i = 0
        for ch in raw:
            try:
                mods.add(Modifier(ch))
                i += 1
            except ValueError:
                break
        return frozenset(mods), raw[i:]


@dataclass(frozen=True)
class HotkeyBinding:
    """A hotkey -> teleport-point name binding loaded from ``hotkey.txt``."""

    raw_combo: str  # e.g. "^1", "!a"
    point_name: str

    @property
    def modifiers(self) -> frozenset[Modifier]:
        return Modifier.parse_prefix(self.raw_combo)[0]

    @property
    def key(self) -> str:
        return Modifier.parse_prefix(self.raw_combo)[1]


def points_to_category_dict(points: Sequence[TeleportPoint]) -> "list[Category]":
    """Bucket a flat point list into ordered :class:`Category` objects."""
    order: list[str] = []
    buckets: dict[str, Category] = {}
    for point in points:
        cat_name = point.category
        if cat_name not in buckets:
            buckets[cat_name] = Category(name=cat_name)
            order.append(cat_name)
        buckets[cat_name].add(point)
    return [buckets[name] for name in order]
