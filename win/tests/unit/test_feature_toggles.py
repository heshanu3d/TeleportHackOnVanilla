"""Tests for :class:`FeatureService` toggles."""

from __future__ import annotations

import pytest

from teleport_hack.application.feature_toggles import FeatureService
from teleport_hack.domain.versions import VERSION_1_12_3, VERSION_3_3_5
from teleport_hack.infrastructure.memory.null_backend import NullBackend


def _backend_with(addr_kind_value):
    b = NullBackend()
    for addr, kind, value in addr_kind_value:
        b.set_read(addr, kind, value)
    return b


# --- AntiJump --------------------------------------------------------------


def test_anti_jump_off_to_on():
    v = VERSION_1_12_3
    backend = _backend_with([(v.anti_jump, "byte", 0x75)])
    svc = FeatureService(backend, v)

    assert svc.toggle_anti_jump() is True
    writes = [(w.address, w.value) for w in backend.writes if w.kind == "byte"]
    assert (v.anti_jump, 0xEB) in writes
    # Gravity also patched to 0.0
    grav = [w for w in backend.writes if w.address == v.jump_gravity]
    assert grav and grav[0].value == 0.0


def test_anti_jump_on_to_off():
    v = VERSION_1_12_3
    backend = _backend_with([(v.anti_jump, "byte", 0xEB)])
    svc = FeatureService(backend, v)
    assert svc.toggle_anti_jump() is False


def test_anti_jump_unknown_state_raises():
    v = VERSION_1_12_3
    backend = _backend_with([(v.anti_jump, "byte", 0x42)])
    with pytest.raises(ValueError):
        FeatureService(backend, v).toggle_anti_jump()


def test_anti_jump_unsupported_on_335():
    backend = NullBackend()
    with pytest.raises(ValueError):
        FeatureService(backend, VERSION_3_3_5).toggle_anti_jump()


# --- Autoloot --------------------------------------------------------------


def test_autoloot_off_to_on_writes_two_nops():
    v = VERSION_1_12_3
    backend = _backend_with([
        (v.autoloot_2, "byte", 0x74),
        (v.autoloot_2 + 1, "byte", 0x10),
    ])
    svc = FeatureService(backend, v)
    assert svc.toggle_autoloot() is True
    bytes_written = [(w.address, w.value) for w in backend.writes]
    assert (v.autoloot_2, 0x90) in bytes_written
    assert (v.autoloot_2 + 1, 0x90) in bytes_written


def test_autoloot_on_to_off():
    v = VERSION_1_12_3
    backend = _backend_with([
        (v.autoloot_2, "byte", 0x90),
        (v.autoloot_2 + 1, "byte", 0x90),
    ])
    assert FeatureService(backend, v).toggle_autoloot() is False


# --- LuaUnlock -------------------------------------------------------------


def test_lua_unlock_off_to_on():
    v = VERSION_1_12_3
    off = (0x56, 0x8B, 0xF1, 0x0F, 0x84, 0xB1)
    backend = _backend_with([(v.lua_unlock + i, "byte", b) for i, b in enumerate(off)])
    svc = FeatureService(backend, v)
    assert svc.toggle_lua_unlock() is True
    on = (0xB8, 0x01, 0x00, 0x00, 0x00, 0xC3)
    written = [(w.address, w.value) for w in backend.writes]
    for i, b in enumerate(on):
        assert (v.lua_unlock + i, b) in written


# --- Speed -----------------------------------------------------------------


def test_set_speed_walks_pointer_chain_on_335():
    v = VERSION_3_3_5
    base = 0x9000
    pb1 = 0x9100
    pb2 = 0x9200
    backend = NullBackend()
    backend.set_read(v.static_player, "pointer", pb1)
    backend.set_read(pb1 + v.pb_pointer1, "pointer", pb2)
    backend.set_read(pb2 + v.pb_pointer2, "pointer", base)

    FeatureService(backend, v).set_speed(12.5)

    writes = [w for w in backend.writes if w.address == base + v.speed_global]
    assert writes and writes[0].value == 12.5


def test_set_speed_no_op_on_vanilla():
    v = VERSION_1_12_3
    backend = NullBackend()
    FeatureService(backend, v).set_speed(99.0)
    assert backend.writes == []
