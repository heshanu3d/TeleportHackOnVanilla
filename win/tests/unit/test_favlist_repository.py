"""Tests for the favlist file repository."""

from __future__ import annotations

from pathlib import Path

from teleport_hack.domain.models import Position, TeleportPoint
from teleport_hack.infrastructure.repository.favlist import FavlistRepository


def test_load_single_line_format(tmp_path: Path):
    p = tmp_path / "fav.fav"
    p.write_text(
        "主城-暴风城-英雄谷#-9023.236#465.42#94.621\n"
        "主城-暴风城-贸易区#-8843.535#625.114#94.281\n",
        encoding="utf-8",
    )
    repo = FavlistRepository(p)
    points = repo.load()
    assert len(points) == 2
    assert points[0].description == "主城-暴风城-英雄谷"
    assert points[0].position == Position(-9023.236, 465.42, 94.621)


def test_load_legacy_4_line_format(tmp_path: Path):
    p = tmp_path / "fav.fav"
    p.write_text(
        "desc-a\n1.0\n2.0\n3.0\n"
        "desc-b\n4.0\n5.0\n6.0\n",
        encoding="utf-8",
    )
    points = FavlistRepository(p).load()
    assert [pt.description for pt in points] == ["desc-a", "desc-b"]
    assert points[1].position == Position(4.0, 5.0, 6.0)


def test_load_missing_file_returns_empty(tmp_path: Path):
    assert FavlistRepository(tmp_path / "missing.fav").load() == []


def test_save_round_trips(tmp_path: Path):
    p = tmp_path / "out.fav"
    repo = FavlistRepository(p)
    points = [
        TeleportPoint("a-1", Position(1.0, 2.5, -3.25)),
        TeleportPoint("b-2", Position(0.0, 0.0, 0.0)),
    ]
    n = repo.save(points)
    assert n == 2
    reloaded = repo.load()
    assert reloaded == points


def test_malformed_lines_are_skipped(tmp_path: Path):
    p = tmp_path / "fav.fav"
    p.write_text("desc#bad#bad#bad\nok-c#1#2#3\n", encoding="utf-8")
    points = FavlistRepository(p).load()
    assert len(points) == 1
    assert points[0].description == "ok-c"
