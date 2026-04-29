"""Tests for the hotkey combo parser and :class:`HotkeyService`."""

from __future__ import annotations

from pathlib import Path

import pytest

from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.application.hotkey_service import HotkeyService
from teleport_hack.domain.models import HotkeyBinding, Position, TeleportPoint
from teleport_hack.infrastructure.hotkey.manager import HotkeyManager, parse_combo
from teleport_hack.infrastructure.repository.favlist import FavlistRepository


class TestParseCombo:
    def test_ctrl_alt_digit(self):
        assert parse_combo("^!1") == "<ctrl>+<alt>+1"

    def test_alt_letter(self):
        assert parse_combo("!a") == "<alt>+a"

    def test_shift_letter(self):
        assert parse_combo("+x") == "<shift>+x"

    def test_no_modifier(self):
        assert parse_combo("z") == "z"

    def test_uppercase_normalised(self):
        assert parse_combo("!A") == "<alt>+a"

    def test_missing_key_raises(self):
        with pytest.raises(ValueError):
            parse_combo("^!")


class FakeManager:
    """Drop-in replacement that captures ``register`` calls."""

    def __init__(self) -> None:
        self.bindings: dict[str, callable] = {}
        self.cleared = 0
        self.started = 0

    def clear(self):
        self.bindings.clear()
        self.cleared += 1

    def register(self, raw_combo, callback):
        self.bindings[raw_combo] = callback

    def start(self):
        self.started += 1


def test_hotkey_service_binds_known_points(tmp_path: Path):
    repo = FavlistRepository(tmp_path / "fav.fav")
    repo.save([TeleportPoint("斯坦索姆-入口", Position(1.0, 2.0, 3.0))])
    favs = FavouritesService(repo)
    favs.reload()

    fired: list[Position] = []
    fake = FakeManager()
    svc = HotkeyService(fake, favs, fired.append)

    bound = svc.apply([
        HotkeyBinding("^1", "斯坦索姆-入口"),
        HotkeyBinding("^2", "missing-point"),
    ])

    assert bound == 1
    assert "^1" in fake.bindings
    assert fake.started == 1
    fake.bindings["^1"]()
    assert fired == [Position(1.0, 2.0, 3.0)]
