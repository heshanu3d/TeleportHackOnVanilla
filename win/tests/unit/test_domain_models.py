"""Tests for :mod:`teleport_hack.domain.models`."""

from __future__ import annotations

import math

import pytest

from teleport_hack.domain.models import (
    ALL_CATEGORY,
    OTHER_CATEGORY,
    Category,
    HotkeyBinding,
    Modifier,
    Position,
    TeleportPoint,
    points_to_category_dict,
)


class TestPosition:
    def test_as_tuple(self):
        assert Position(1.0, 2.0, 3.0).as_tuple() == (1.0, 2.0, 3.0)

    def test_distance(self):
        a = Position(0.0, 0.0, 0.0)
        b = Position(3.0, 4.0, 0.0)
        assert math.isclose(a.distance_to(b), 5.0)

    def test_from_strings(self):
        p = Position.from_strings("1", "2.5", "-3.25")
        assert p == Position(1.0, 2.5, -3.25)

    def test_from_strings_invalid(self):
        with pytest.raises(ValueError):
            Position.from_strings("a", "b", "c")


class TestTeleportPoint:
    def test_category_extracts_prefix_before_dash(self):
        p = TeleportPoint("斯坦索姆-入口", Position(1, 2, 3))
        assert p.category == "斯坦索姆"

    def test_category_falls_back_to_other_when_no_dash(self):
        assert TeleportPoint("无分类", Position(1, 2, 3)).category == OTHER_CATEGORY

    def test_serialization_format(self):
        p = TeleportPoint("desc", Position(-9023.236, 465.42, 94.621))
        fields = p.to_serialized_fields()
        assert fields[0] == "desc"
        # Floats should round-trip without unnecessary trailing zeros.
        assert "0000" not in fields[1]
        assert float(fields[1]) == -9023.236

    def test_serialization_integers_have_no_dot(self):
        p = TeleportPoint("d", Position(1.0, 2.0, 3.0))
        assert p.to_serialized_fields() == ("d", "1", "2", "3")


class TestModifier:
    def test_parse_prefix_extracts_modifiers(self):
        mods, key = Modifier.parse_prefix("^!1")
        assert mods == frozenset({Modifier.CTRL, Modifier.ALT})
        assert key == "1"

    def test_parse_prefix_no_modifiers(self):
        mods, key = Modifier.parse_prefix("a")
        assert mods == frozenset()
        assert key == "a"

    def test_parse_prefix_only_shift(self):
        mods, key = Modifier.parse_prefix("+x")
        assert mods == {Modifier.SHIFT}
        assert key == "x"


class TestHotkeyBinding:
    def test_modifier_and_key_extraction(self):
        b = HotkeyBinding("^!1", "斯坦索姆-入口")
        assert b.modifiers == {Modifier.CTRL, Modifier.ALT}
        assert b.key == "1"


class TestCategoryBucketing:
    def test_groups_in_insertion_order(self):
        pts = [
            TeleportPoint("a-x", Position(0, 0, 0)),
            TeleportPoint("b-y", Position(0, 0, 0)),
            TeleportPoint("a-z", Position(0, 0, 0)),
        ]
        cats = points_to_category_dict(pts)
        assert [c.name for c in cats] == ["a", "b"]
        assert len(cats[0]) == 2
        assert len(cats[1]) == 1

    def test_unbucketed_goes_to_other(self):
        pts = [TeleportPoint("nodash", Position(0, 0, 0))]
        cats = points_to_category_dict(pts)
        assert cats[0].name == OTHER_CATEGORY
