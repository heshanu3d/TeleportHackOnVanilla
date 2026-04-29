"""Application entry point — wires services then launches the GUI."""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path
from typing import List, Optional

from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.application.settings import SettingsRepository
from teleport_hack.domain.versions import VERSIONS, get_version
from teleport_hack.infrastructure.memory.factory import is_windows, list_wow_processes
from teleport_hack.infrastructure.repository.favlist import FavlistRepository

log = logging.getLogger(__name__)


def _parse_args(argv: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="teleport-hack")
    parser.add_argument(
        "--version", choices=sorted(VERSIONS.keys()), default=None,
        help="WoW client build to attach to (overrides settings.json).",
    )
    parser.add_argument(
        "--favlist", type=Path, default=None,
        help="Path to the favourites file (overrides settings.json).",
    )
    parser.add_argument(
        "--hotkeys", type=Path, default=None,
        help="Path to the hotkey config (overrides settings.json).",
    )
    parser.add_argument(
        "--settings", type=Path, default=Path("settings.json"),
        help="Path to settings.json (default: ./settings.json)",
    )
    parser.add_argument(
        "--pid", type=int, default=None,
        help="Attach to a specific WoW PID (otherwise the first found is used).",
    )
    parser.add_argument(
        "--log-level", default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
    )
    return parser.parse_args(argv[1:])


def run(argv: Optional[List[str]] = None) -> int:
    args = _parse_args(argv or sys.argv)
    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s %(levelname)-7s %(name)s: %(message)s",
    )

    settings_repo = SettingsRepository(args.settings)
    settings = settings_repo.load()

    # CLI overrides take precedence; otherwise use settings values.
    version_name = args.version or settings.default_version
    favlist_path = args.favlist or Path(settings.favlist_path)
    hotkey_path = args.hotkeys or Path(settings.hotkey_path)

    version = get_version(version_name)
    if version is None:
        log.error("Unknown version: %s", version_name)
        return 2

    favourites = FavouritesService(FavlistRepository(favlist_path))
    favourites.reload()

    pid: Optional[int] = args.pid
    backend_error: Optional[str] = None

    if is_windows():
        if pid is None:
            procs = list_wow_processes(version.executable)
            if procs:
                pid = procs[0][0]
            else:
                backend_error = "No running WoW.exe found."
    else:
        backend_error = "Memory operations are only supported on Windows."

    # Build Qt app lazily so unit tests don't import PySide6.
    from PySide6.QtWidgets import QApplication

    from teleport_hack.presentation.main_window import MainWindow

    app = QApplication.instance() or QApplication(sys.argv)
    window = MainWindow(
        favourites=favourites,
        version=version,
        hotkey_config_path=hotkey_path,
        settings_repository=settings_repo,
        settings=settings,
        pid=pid,
        backend_error=backend_error,
    )
    window.show()
    return app.exec()
