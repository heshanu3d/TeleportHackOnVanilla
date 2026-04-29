"""Tests for :mod:`teleport_hack.domain.versions`."""

from teleport_hack.domain.versions import VERSIONS, get_version


def test_known_versions_present():
    assert set(VERSIONS) == {"1.12.1", "1.12.3", "3.3.5"}


def test_pointer_chain_only_for_3_3_5():
    assert VERSIONS["3.3.5"].is_pointer_chain
    assert not VERSIONS["1.12.1"].is_pointer_chain
    assert not VERSIONS["1.12.3"].is_pointer_chain


def test_speed_only_supported_on_3_3_5():
    assert VERSIONS["3.3.5"].supports_speed
    assert not VERSIONS["1.12.1"].supports_speed


def test_anti_jump_only_on_vanilla():
    assert VERSIONS["1.12.1"].supports_anti_jump
    assert VERSIONS["1.12.3"].supports_anti_jump
    assert not VERSIONS["3.3.5"].supports_anti_jump


def test_unknown_version_returns_none():
    assert get_version("0.0.0") is None
