"""Tests for :class:`FavouritesPorter` (export/import/merge)."""

from __future__ import annotations

from pathlib import Path

import pytest

from teleport_hack.application.favourites_porter import FavouritesPorter
from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.domain.models import Position, TeleportPoint
from teleport_hack.infrastructure.repository.favlist import FavlistRepository


@pytest.fixture
def service(tmp_path: Path) -> FavouritesService:
    repo = FavlistRepository(tmp_path / "fav.fav")
    repo.save([
        TeleportPoint("a-1", Position(1, 1, 1)),
        TeleportPoint("b-1", Position(2, 2, 2)),
    ])
    s = FavouritesService(repo)
    s.reload()
    return s


def test_export_writes_current_points(tmp_path: Path, service):
    target = tmp_path / "out.fav"
    n = FavouritesPorter(service).export_to(target)
    assert n == 2
    reloaded = FavlistRepository(target).load()
    assert reloaded == list(service.all_points)


def test_import_replace_swaps_contents(tmp_path: Path, service):
    other = tmp_path / "other.fav"
    FavlistRepository(other).save([
        TeleportPoint("c-1", Position(10, 10, 10)),
    ])
    n = FavouritesPorter(service).import_replace(other)
    assert n == 1
    assert [p.description for p in service.all_points] == ["c-1"]


def test_import_merge_adds_new_skips_duplicates(tmp_path: Path, service):
    other = tmp_path / "merge.fav"
    FavlistRepository(other).save([
        TeleportPoint("a-1", Position(1, 1, 1)),       # exact dup → skip
        TeleportPoint("a-1", Position(1, 1, 9)),       # same desc, diff pos → add
        TeleportPoint("c-new", Position(7, 8, 9)),     # totally new → add
    ])
    report = FavouritesPorter(service).import_merge(other)
    assert report.added == 2
    assert report.skipped_duplicates == 1
    descs = [p.description for p in service.all_points]
    assert descs.count("a-1") == 2
    assert "c-new" in descs


def test_merge_points_inline(service):
    report = FavouritesPorter(service).merge_points([
        TeleportPoint("b-1", Position(2, 2, 2)),  # dup
        TeleportPoint("z-z", Position(0, 0, 0)),  # new
    ])
    assert report.added == 1
    assert report.skipped_duplicates == 1
    assert report.total_examined == 2
