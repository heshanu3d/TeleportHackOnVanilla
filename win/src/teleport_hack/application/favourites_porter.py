"""Import / export / merge favourites with another file.

Pure logic — no UI; sits at the application layer alongside
:class:`FavouritesService`.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List

from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.domain.models import Position, TeleportPoint
from teleport_hack.infrastructure.repository.favlist import FavlistRepository


@dataclass(frozen=True)
class MergeReport:
    added: int
    skipped_duplicates: int

    @property
    def total_examined(self) -> int:
        return self.added + self.skipped_duplicates


def _signature(p: TeleportPoint) -> tuple[str, float, float, float]:
    """Identity used for de-duplication: description + exact position."""
    return (p.description, p.position.x, p.position.y, p.position.z)


class FavouritesPorter:
    """Exporter / importer / merger of favourites files."""

    def __init__(self, service: FavouritesService) -> None:
        self._service = service

    # ---------------------------------------------------------------- export

    def export_to(self, path: Path | str) -> int:
        """Write the *current* favourites to ``path``. Returns count."""
        return FavlistRepository(path).save(self._service.all_points)

    # ---------------------------------------------------------------- import

    def import_replace(self, path: Path | str) -> int:
        """Replace all favourites with the contents of ``path``."""
        loaded = FavlistRepository(path).load()
        # Replace in-place to keep the same service instance.
        self._service._points = list(loaded)  # type: ignore[attr-defined]
        return len(loaded)

    def import_merge(self, path: Path | str) -> MergeReport:
        """Merge contents of ``path`` into current favourites; skip duplicates."""
        incoming = FavlistRepository(path).load()
        return self._merge(incoming)

    def merge_points(self, points: Iterable[TeleportPoint]) -> MergeReport:
        return self._merge(list(points))

    # --------------------------------------------------------------- private

    def _merge(self, incoming: List[TeleportPoint]) -> MergeReport:
        existing = {_signature(p) for p in self._service.all_points}
        added = 0
        skipped = 0
        for pt in incoming:
            sig = _signature(pt)
            if sig in existing:
                skipped += 1
                continue
            existing.add(sig)
            self._service.add(pt)
            added += 1
        return MergeReport(added=added, skipped_duplicates=skipped)
