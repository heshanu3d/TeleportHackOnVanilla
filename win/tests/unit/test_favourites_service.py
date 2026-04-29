"""Tests for :class:`FavouritesService` (CRUD + category logic)."""

from __future__ import annotations

from pathlib import Path

import pytest

from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.domain.models import ALL_CATEGORY, Position, TeleportPoint
from teleport_hack.infrastructure.repository.favlist import FavlistRepository


@pytest.fixture
def service(tmp_path: Path) -> FavouritesService:
    repo = FavlistRepository(tmp_path / "fav.fav")
    repo.save([
        TeleportPoint("a-1", Position(1, 1, 1)),
        TeleportPoint("a-2", Position(2, 2, 2)),
        TeleportPoint("b-1", Position(3, 3, 3)),
    ])
    s = FavouritesService(repo)
    s.reload()
    return s


def test_categories_in_insertion_order(service):
    assert service.category_names() == ["a", "b"]


def test_points_in_category(service):
    pts = service.points_in_category("a")
    assert [p.description for p in pts] == ["a-1", "a-2"]
    assert len(service.points_in_category(ALL_CATEGORY)) == 3


def test_find_by_name(service):
    assert service.find_by_name("b-1").position == Position(3, 3, 3)
    assert service.find_by_name("missing") is None


def test_insert_in_category_uses_global_index(service):
    new_pt = TeleportPoint("a-mid", Position(9, 9, 9))
    service.insert_in_category("a", 1, new_pt)
    assert [p.description for p in service.points_in_category("a")] == [
        "a-1", "a-mid", "a-2",
    ]
    # Global ordering retains the b-1 tail
    assert service.all_points[-1].description == "b-1"


def test_insert_at_zero_puts_at_start_of_category(service):
    new_pt = TeleportPoint("a-head", Position(0, 0, 0))
    service.insert_in_category("a", 0, new_pt)
    assert service.points_in_category("a")[0].description == "a-head"


def test_append_in_category_inserts_after_row(service):
    new_pt = TeleportPoint("a-after-1", Position(0, 0, 0))
    service.append_in_category("a", 0, new_pt)  # after a-1
    assert [p.description for p in service.points_in_category("a")] == [
        "a-1", "a-after-1", "a-2",
    ]


def test_append_at_last_row_puts_at_end_of_category(service):
    new_pt = TeleportPoint("a-tail", Position(0, 0, 0))
    service.append_in_category("a", 1, new_pt)  # after last 'a' row
    assert service.points_in_category("a")[-1].description == "a-tail"


def test_insert_into_all_category(service):
    new_pt = TeleportPoint("z-end", Position(0, 0, 0))
    service.insert_in_category(ALL_CATEGORY, 3, new_pt)
    assert service.all_points[-1] == new_pt


def test_replace_in_category(service):
    replacement = TeleportPoint("a-replaced", Position(7, 7, 7))
    service.replace_in_category("a", 0, replacement)
    assert service.all_points[0] == replacement


def test_delete_in_category(service):
    removed = service.delete_in_category("a", 0)
    assert removed.description == "a-1"
    assert [p.description for p in service.all_points] == ["a-2", "b-1"]


def test_delete_out_of_range(service):
    with pytest.raises(IndexError):
        service.delete_in_category("a", 99)


def test_save_persists(service, tmp_path):
    new_pt = TeleportPoint("c-new", Position(4, 4, 4))
    service.add(new_pt)
    n = service.save()
    assert n == 4
    reloaded = FavlistRepository(tmp_path / "fav.fav").load()
    assert reloaded[-1] == new_pt
