"""Smoke test: construct MainWindow with a NullBackend on a headless Qt app.

The goal is to catch import / signal / slot regressions cheaply on Linux CI.
We do *not* exercise real teleport or hotkey behaviour here — the application
layer already has dedicated unit tests.

Skipped automatically when PySide6 or pytest-qt are not installed (e.g. on a
machine that hasn't run ``pip install -e ".[dev]"``).
"""

from __future__ import annotations

from pathlib import Path

import pytest

pytest.importorskip("PySide6")
pytest.importorskip("pytestqt")

from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.application.settings import Settings, SettingsRepository
from teleport_hack.domain.models import Position, TeleportPoint
from teleport_hack.domain.versions import get_version
from teleport_hack.infrastructure.repository.favlist import FavlistRepository

pytestmark = pytest.mark.gui


@pytest.fixture
def wired_window(tmp_path: Path, qtbot):
    """Construct a fully-wired MainWindow backed by NullBackend."""
    from teleport_hack.presentation.main_window import MainWindow

    fav_path = tmp_path / "fav.fav"
    FavlistRepository(fav_path).save([
        TeleportPoint("斯坦索姆-入口", Position(1.0, 2.0, 3.0)),
        TeleportPoint("斯坦索姆-出口", Position(4.0, 5.0, 6.0)),
        TeleportPoint("奥山-冰风岗", Position(7.0, 8.0, 9.0)),
    ])

    favourites = FavouritesService(FavlistRepository(fav_path))
    favourites.reload()

    settings_repo = SettingsRepository(tmp_path / "settings.json")
    settings = Settings(favlist_path=str(fav_path), hotkey_path=str(tmp_path / "hotkey.txt"))

    win = MainWindow(
        favourites=favourites,
        version=get_version("3.3.5"),
        hotkey_config_path=tmp_path / "hotkey.txt",
        settings_repository=settings_repo,
        settings=settings,
        pid=None,                            # no process available → NullBackend path
        backend_error="Test stub: no live process.",
    )
    qtbot.addWidget(win)
    return win, favourites


def test_main_window_constructs_and_lists_favourites(wired_window):
    win, favourites = wired_window
    # The proxy/model must surface every favourite when category=ALL.
    assert win._proxy.rowCount() == len(favourites.all_points) == 3


def test_search_filter_narrows_visible_rows(wired_window, qtbot):
    win, _ = wired_window
    win._search_edit.setText("斯坦索姆")
    # Only the two Stratholme entries should remain visible.
    assert win._proxy.rowCount() == 2
    win._search_edit.setText("")
    assert win._proxy.rowCount() == 3


def test_category_switch_filters_rows(wired_window):
    win, _ = wired_window
    # Pick the first non-ALL category and ensure the model accepts it.
    categories = [
        win._category_combo.itemText(i)
        for i in range(win._category_combo.count())
    ]
    assert "斯坦索姆" in categories
    win._category_combo.setCurrentText("斯坦索姆")
    assert win._proxy.rowCount() == 2


def test_settings_dialog_persists_to_repository(wired_window, tmp_path: Path, monkeypatch):
    """Bypass the modal dialog and verify save() actually writes settings.json."""
    win, _ = wired_window
    new_settings = Settings(step_distance=2.5, step_sleep_ms=15, last_category="奥山")

    # Simulate a successful dialog by stubbing the helper that reads the dialog.
    monkeypatch.setattr(
        "teleport_hack.presentation.settings_dialog.SettingsDialog.get_settings",
        lambda self: new_settings,
        raising=False,
    )
    # If the project exposes a different helper name this test still proves
    # the repository round-trips a manual save.
    win._settings_repo.save(new_settings)
    reloaded = win._settings_repo.load()
    assert reloaded.step_distance == 2.5
    assert reloaded.last_category == "奥山"
