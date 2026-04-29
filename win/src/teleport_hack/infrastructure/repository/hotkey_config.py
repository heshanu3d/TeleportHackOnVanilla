"""Read the simple ``hotkey.txt`` config file.

Format::

    # comment line (any line starting with '#')
    ^1
    斯坦索姆-入口
    ^2
    斯坦索姆-出口
    ...

Pairs of (combo, point-name) lines. Comment / blank lines are ignored.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable, List

from teleport_hack.domain.models import HotkeyBinding


class HotkeyConfigRepository:
    def __init__(self, path: Path | str) -> None:
        self._path = Path(path)

    @property
    def path(self) -> Path:
        return self._path

    def load(self) -> List[HotkeyBinding]:
        if not self._path.exists():
            return []
        raw = self._path.read_text(encoding="utf-8").splitlines()
        return list(self._parse(raw))

    @staticmethod
    def _parse(lines: Iterable[str]) -> Iterable[HotkeyBinding]:
        cleaned = [
            line.strip()
            for line in lines
            if line.strip() and not line.lstrip().startswith("#")
        ]
        for combo, name in zip(cleaned[0::2], cleaned[1::2]):
            yield HotkeyBinding(raw_combo=combo, point_name=name)
