"""Manage the in-memory favourites collection plus persistence.

Owns a flat list of :class:`TeleportPoint` and exposes category-aware
operations. UI-friendly: returns ordered category names and 2D rows.
"""

from __future__ import annotations

from typing import List, Optional

from teleport_hack.domain.models import (
    ALL_CATEGORY,
    Category,
    Position,
    TeleportPoint,
    points_to_category_dict,
)
from teleport_hack.infrastructure.repository.favlist import FavlistRepository


class FavouritesService:
    def __init__(self, repository: FavlistRepository) -> None:
        self._repo = repository
        self._points: List[TeleportPoint] = []

    # ------------------------------------------------------------- I/O

    def reload(self) -> None:
        self._points = self._repo.load()

    def save(self) -> int:
        return self._repo.save(self._points)

    # ------------------------------------------------------------- queries

    @property
    def all_points(self) -> tuple[TeleportPoint, ...]:
        return tuple(self._points)

    def categories(self) -> List[Category]:
        """Return categories in original insertion order, excluding ``所有``."""
        return points_to_category_dict(self._points)

    def category_names(self) -> List[str]:
        """Names suitable for a combobox (excludes the synthetic ``所有``)."""
        return [c.name for c in self.categories()]

    def points_in_category(self, name: str) -> List[TeleportPoint]:
        if name == ALL_CATEGORY:
            return list(self._points)
        return [p for p in self._points if p.category == name]

    def find_by_name(self, description: str) -> Optional[TeleportPoint]:
        for p in self._points:
            if p.description == description:
                return p
        return None

    # ------------------------------------------------------------- mutations

    def add(self, point: TeleportPoint) -> None:
        self._points.append(point)

    def insert_in_category(self, category: str, index: int, point: TeleportPoint) -> None:
        """Insert ``point`` *before* the visible row ``index`` within ``category``."""
        global_index = self._global_index(category, index)
        self._points.insert(global_index, point)

    def append_in_category(self, category: str, index: int, point: TeleportPoint) -> None:
        """Insert ``point`` *after* the visible row ``index`` within ``category``.

        Equivalent to inserting at ``index + 1``.
        """
        self.insert_in_category(category, index + 1, point)

    def replace_in_category(self, category: str, index: int, point: TeleportPoint) -> None:
        global_index = self._global_index(category, index, allow_end=False)
        self._points[global_index] = point

    def delete_in_category(self, category: str, index: int) -> TeleportPoint:
        global_index = self._global_index(category, index, allow_end=False)
        return self._points.pop(global_index)

    # ------------------------------------------------------------- helpers

    def _global_index(self, category: str, local_index: int, *, allow_end: bool = True) -> int:
        if category == ALL_CATEGORY:
            return local_index

        seen = 0
        for i, p in enumerate(self._points):
            if p.category != category:
                continue
            if seen == local_index:
                return i
            seen += 1
        if allow_end and local_index == seen:
            # Append at the end of the file
            return len(self._points)
        raise IndexError(
            f"Index {local_index} out of range in category {category!r} "
            f"(size={seen})"
        )

    @staticmethod
    def make_point(description: str, position: Position) -> TeleportPoint:
        return TeleportPoint(description=description, position=position)
