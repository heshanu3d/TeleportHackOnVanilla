"""Tests for :func:`read_player_name`."""

from __future__ import annotations

from teleport_hack.infrastructure.memory.factory import read_player_name
from teleport_hack.infrastructure.memory.null_backend import NullBackend


def test_returns_none_when_address_zero():
    backend = NullBackend()
    assert read_player_name(backend, 0) is None


def test_returns_none_when_buffer_all_zero():
    backend = NullBackend()
    assert read_player_name(backend, 0x1000) is None


def test_decodes_utf8_and_trims_at_nul():
    backend = NullBackend()
    backend.set_read(0x1000, "bytes", "Hsbot\x00garbage".encode("utf-8"))
    assert read_player_name(backend, 0x1000, length=12) == "Hsbot"


def test_handles_chinese_player_name():
    backend = NullBackend()
    backend.set_read(0x2000, "bytes", "牧师\x00".encode("utf-8"))
    assert read_player_name(backend, 0x2000, length=10) == "牧师"
