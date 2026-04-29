"""Tests for the hotkey-config file repository."""

from __future__ import annotations

from pathlib import Path

from teleport_hack.domain.models import Modifier
from teleport_hack.infrastructure.repository.hotkey_config import HotkeyConfigRepository


def test_load_skips_comments_and_blank_lines(tmp_path: Path):
    p = tmp_path / "hotkey.txt"
    p.write_text(
        "# first line is comment. +shift, ^ctrl, !alt\n"
        "^1\n"
        "斯坦索姆-入口\n"
        "\n"
        "!2\n"
        "斯坦索姆-蜘蛛\n",
        encoding="utf-8",
    )
    bindings = HotkeyConfigRepository(p).load()
    assert len(bindings) == 2
    assert bindings[0].raw_combo == "^1"
    assert bindings[0].point_name == "斯坦索姆-入口"
    assert bindings[0].modifiers == {Modifier.CTRL}
    assert bindings[1].modifiers == {Modifier.ALT}


def test_load_missing_file_returns_empty(tmp_path: Path):
    assert HotkeyConfigRepository(tmp_path / "missing.txt").load() == []


def test_unpaired_trailing_line_is_dropped(tmp_path: Path):
    p = tmp_path / "hotkey.txt"
    p.write_text("^1\nname-a\n^2\n", encoding="utf-8")  # ^2 has no pair
    bindings = HotkeyConfigRepository(p).load()
    assert len(bindings) == 1
    assert bindings[0].raw_combo == "^1"
