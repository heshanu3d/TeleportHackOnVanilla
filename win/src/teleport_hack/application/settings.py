"""User-tweakable application settings, persisted as JSON.

Intentionally lives at the application layer (not infrastructure) because
it represents a domain concept ("user preferences") and is consumed by
multiple services. The on-disk format is JSON; the file lives next to
the project (``./settings.json`` by default).
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field, fields
from pathlib import Path
from typing import Any, Mapping


@dataclass
class Settings:
    """All persistable user settings."""

    # Step-teleport tuning
    step_distance: float = 10.0
    step_sleep_ms: int = 40

    # Default game version when none is passed via CLI
    default_version: str = "3.3.5"

    # Default favourites / hotkey paths (used by the settings dialog)
    favlist_path: str = "favlist.fav"
    hotkey_path: str = "hotkey.txt"

    # UI preferences
    last_category: str = "所有"
    speed_value: float = 7.0
    fast_step: bool = False  # skip {Left}/{Right} taps after teleport

    # ----------------------------------------------------------- (de)serialise

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> "Settings":
        known = {f.name for f in fields(cls)}
        return cls(**{k: v for k, v in data.items() if k in known})


class SettingsRepository:
    """Read/write a JSON settings file. Returns defaults if missing/corrupt."""

    def __init__(self, path: Path | str) -> None:
        self._path = Path(path)

    @property
    def path(self) -> Path:
        return self._path

    def load(self) -> Settings:
        if not self._path.exists():
            return Settings()
        try:
            data = json.loads(self._path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return Settings()
        if not isinstance(data, dict):
            return Settings()
        return Settings.from_dict(data)

    def save(self, settings: Settings) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(
            json.dumps(settings.to_dict(), indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
