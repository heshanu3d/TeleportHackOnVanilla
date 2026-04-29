"""Tests for :class:`TeleportService` using :class:`NullBackend`."""

from __future__ import annotations

import struct

import pytest

from teleport_hack.application.teleport_service import StepConfig, TeleportService
from teleport_hack.domain.models import Position
from teleport_hack.domain.versions import VERSION_1_12_3, VERSION_3_3_5
from teleport_hack.infrastructure.memory.null_backend import NullBackend


# --- 3.3.5 (pointer chain) -------------------------------------------------


def _setup_335_chain(backend: NullBackend, base: int = 0x1000) -> None:
    v = VERSION_3_3_5
    pb1 = base + 0x100
    pb2 = base + 0x200
    backend.set_read(v.static_player, "pointer", pb1)
    backend.set_read(pb1 + v.pb_pointer1, "pointer", pb2)
    backend.set_read(pb2 + v.pb_pointer2, "pointer", base)


def test_335_read_position_walks_pointer_chain():
    backend = NullBackend()
    base = 0x10000
    _setup_335_chain(backend, base)
    backend.set_read(base + VERSION_3_3_5.pos_x, "float", 1.5)
    backend.set_read(base + VERSION_3_3_5.pos_y, "float", 2.5)
    backend.set_read(base + VERSION_3_3_5.pos_z, "float", 3.5)

    svc = TeleportService(backend, VERSION_3_3_5)
    assert svc.read_position() == Position(1.5, 2.5, 3.5)


def test_335_write_swaps_x_and_y():
    backend = NullBackend()
    base = 0x10000
    _setup_335_chain(backend, base)
    svc = TeleportService(backend, VERSION_3_3_5)

    svc.write_position(Position(10.0, 20.0, 30.0))

    writes = {(w.address, w.kind): w.value for w in backend.writes}
    assert writes[(base + VERSION_3_3_5.pos_x, "float")] == 20.0  # got y
    assert writes[(base + VERSION_3_3_5.pos_y, "float")] == 10.0  # got x
    assert writes[(base + VERSION_3_3_5.pos_z, "float")] == 30.0


# --- 1.12.x (multi-level offsets) -----------------------------------------


def test_vanilla_write_walks_offset_chain_per_axis():
    backend = NullBackend()
    v = VERSION_1_12_3

    # Configure read_pointer to return a stable mock value for any address;
    # we don't care about the exact final address here, just that *some*
    # writes happen for x/y/z and that the values are swapped.
    backend.set_read(v.static_player, "pointer", 0x1000)

    svc = TeleportService(backend, v)
    svc.write_position(Position(100.0, 200.0, 300.0))

    # Three writes (one per axis), all floats.
    floats = [w.value for w in backend.writes if w.kind == "float"]
    assert sorted(floats) == [100.0, 200.0, 300.0]
    # First written value corresponds to axis-x address but receives Y due
    # to the documented engine swap.
    assert backend.writes[0].value == 200.0


def test_vanilla_read_swaps_for_1_12_x():
    backend = NullBackend()
    v = VERSION_1_12_3
    backend.set_read(v.curr_pos_x, "float", 11.0)  # engine-x
    backend.set_read(v.curr_pos_y, "float", 22.0)  # engine-y
    backend.set_read(v.curr_pos_z, "float", 33.0)
    svc = TeleportService(backend, v)

    pos = svc.read_position()
    # Original AutoIt for 1.12.1 returned [Y, X, Z]; we apply same swap to all 1.12.x
    assert pos == Position(22.0, 11.0, 33.0)


# --- step-by-step ----------------------------------------------------------


def test_teleport_step_writes_n_intermediate_positions():
    backend = NullBackend()
    base = 0x10000
    _setup_335_chain(backend, base)
    backend.set_read(base + VERSION_3_3_5.pos_x, "float", 0.0)
    backend.set_read(base + VERSION_3_3_5.pos_y, "float", 0.0)
    backend.set_read(base + VERSION_3_3_5.pos_z, "float", 0.0)

    svc = TeleportService(backend, VERSION_3_3_5)
    sleeps: list[float] = []
    steps = svc.teleport_step(
        Position(100.0, 0.0, 0.0),
        StepConfig(distance_per_step=10.0, sleep_between_steps=0.01),
        sleeper=sleeps.append,
    )

    # distance 100 / 10 = 10 + 1 = 11 steps
    assert steps == 11
    # 11 steps × 3 axes = 33 writes
    assert sum(1 for w in backend.writes if w.kind == "float") == 33
    assert len(sleeps) == 11
    assert all(s == pytest.approx(0.01) for s in sleeps)


def test_read_map_id_returns_none_when_unsupported():
    backend = NullBackend()
    svc = TeleportService(backend, VERSION_1_12_3)
    assert svc.read_map_id() is None


def test_read_map_id_returns_value_for_335():
    backend = NullBackend()
    backend.set_read(VERSION_3_3_5.map_id, "uint32", 530)
    svc = TeleportService(backend, VERSION_3_3_5)
    assert svc.read_map_id() == 530
