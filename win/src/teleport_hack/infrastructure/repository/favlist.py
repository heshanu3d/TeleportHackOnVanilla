"""Read/write the AutoIt-compatible ``favlist.fav`` file.

File format (one teleport per line)::

    描述#x#y#z

The original AutoIt code also tolerated a 4-line-per-record fallback layout;
we preserve that on read but always emit the canonical single-line format on
write so files normalise themselves over time.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable, List

from teleport_hack.domain.models import Position, TeleportPoint

DEFAULT_SEPARATOR = "#"
COLUMN_COUNT = 4


class FavlistRepository:
    def __init__(self, path: Path | str, separator: str = DEFAULT_SEPARATOR) -> None:
        self._path = Path(path)
        self._sep = separator

    @property
    def path(self) -> Path:
        return self._path

    # ------------------------------------------------------------------ read

    def load(self) -> List[TeleportPoint]:
        if not self._path.exists():
            return []
        raw_lines = self._path.read_text(encoding="utf-8").splitlines()
        # Trim trailing blanks, but preserve interior ones for the legacy
        # 4-line layout.
        while raw_lines and raw_lines[-1].strip() == "":
            raw_lines.pop()
        return list(self._parse(raw_lines))

    def _parse(self, lines: List[str]) -> Iterable[TeleportPoint]:
        i = 0
        n = len(lines)
        while i < n:
            line = lines[i]
            parts = line.split(self._sep)
            if len(parts) == COLUMN_COUNT:
                desc, x, y, z = parts
                try:
                    yield TeleportPoint(desc, Position.from_strings(x, y, z))
                except ValueError:
                    # Malformed line, skip silently like the AutoIt original.
                    pass
                i += 1
            elif i + COLUMN_COUNT - 1 < n:
                # Legacy 4-line record
                desc = lines[i]
                try:
                    yield TeleportPoint(
                        desc,
                        Position.from_strings(
                            lines[i + 1], lines[i + 2], lines[i + 3]
                        ),
                    )
                except ValueError:
                    pass
                i += COLUMN_COUNT
            else:
                # Trailing junk — abort.
                break

    # ----------------------------------------------------------------- write

    def save(self, points: Iterable[TeleportPoint]) -> int:
        """Write all points and return the number of records persisted."""
        self._path.parent.mkdir(parents=True, exist_ok=True)
        count = 0
        with self._path.open("w", encoding="utf-8", newline="\n") as fh:
            for point in points:
                fh.write(self._sep.join(point.to_serialized_fields()))
                fh.write("\n")
                count += 1
        return count
