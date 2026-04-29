"""Tests for :mod:`teleport_hack.application.settings`."""

from __future__ import annotations

import json
from pathlib import Path

from teleport_hack.application.settings import Settings, SettingsRepository


def test_defaults():
    s = Settings()
    assert s.step_distance == 10.0
    assert s.step_sleep_ms == 40
    assert s.default_version == "3.3.5"
    assert s.last_category == "所有"


def test_round_trip(tmp_path: Path):
    repo = SettingsRepository(tmp_path / "settings.json")
    s = Settings(step_distance=5.5, step_sleep_ms=20, last_category="斯坦索姆")
    repo.save(s)
    reloaded = repo.load()
    assert reloaded.step_distance == 5.5
    assert reloaded.step_sleep_ms == 20
    assert reloaded.last_category == "斯坦索姆"


def test_load_missing_returns_defaults(tmp_path: Path):
    s = SettingsRepository(tmp_path / "missing.json").load()
    assert s == Settings()


def test_load_corrupt_returns_defaults(tmp_path: Path):
    p = tmp_path / "settings.json"
    p.write_text("{not valid json", encoding="utf-8")
    assert SettingsRepository(p).load() == Settings()


def test_load_unknown_keys_ignored(tmp_path: Path):
    p = tmp_path / "settings.json"
    p.write_text(
        json.dumps({"step_distance": 7.0, "extra_unknown_key": "ignored"}),
        encoding="utf-8",
    )
    s = SettingsRepository(p).load()
    assert s.step_distance == 7.0
    assert s.step_sleep_ms == 40  # default preserved


def test_save_creates_parent_directories(tmp_path: Path):
    target = tmp_path / "deep" / "dir" / "settings.json"
    SettingsRepository(target).save(Settings())
    assert target.exists()
