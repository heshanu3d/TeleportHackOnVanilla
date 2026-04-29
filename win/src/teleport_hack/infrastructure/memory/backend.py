"""Backend protocol for reading/writing process memory."""

from __future__ import annotations

from typing import Protocol, runtime_checkable


class MemoryError(Exception):
    """Raised when a memory operation cannot be completed."""


@runtime_checkable
class MemoryBackend(Protocol):
    """Minimal surface required by the application layer.

    All numeric addresses are absolute (already resolved); pointer-chain
    walking lives in :mod:`teleport_hack.application.teleport_service`.
    """

    pid: int

    def is_attached(self) -> bool: ...
    def close(self) -> None: ...

    # Reads
    def read_float(self, address: int) -> float: ...
    def read_uint32(self, address: int) -> int: ...
    def read_byte(self, address: int) -> int: ...
    def read_pointer(self, address: int) -> int: ...
    def read_bytes(self, address: int, length: int) -> bytes: ...

    # Writes
    def write_float(self, address: int, value: float) -> None: ...
    def write_byte(self, address: int, value: int) -> None: ...
