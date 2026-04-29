"""No-op backend used on non-Windows platforms / in tests.

It records every write so tests can assert against them, and returns
deterministic zero-valued reads.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Tuple


@dataclass
class WriteRecord:
    address: int
    kind: str  # "float" | "byte"
    value: float | int


class NullBackend:
    """In-memory stub satisfying :class:`MemoryBackend`."""

    def __init__(self, pid: int = 0) -> None:
        self.pid = pid
        self._closed = False
        self.writes: List[WriteRecord] = []
        # Optional canned responses keyed by (address, kind)
        self._reads: dict[Tuple[int, str], float | int | bytes] = {}

    # ---- helpers used by tests ------------------------------------------
    def set_read(self, address: int, kind: str, value) -> None:
        self._reads[(address, kind)] = value

    # ---- protocol -------------------------------------------------------
    def is_attached(self) -> bool:
        return not self._closed

    def close(self) -> None:
        self._closed = True

    def _read(self, address: int, kind: str, default):
        return self._reads.get((address, kind), default)

    def read_float(self, address: int) -> float:
        return float(self._read(address, "float", 0.0))

    def read_uint32(self, address: int) -> int:
        return int(self._read(address, "uint32", 0))

    def read_byte(self, address: int) -> int:
        return int(self._read(address, "byte", 0))

    def read_pointer(self, address: int) -> int:
        return int(self._read(address, "pointer", 0))

    def read_bytes(self, address: int, length: int) -> bytes:
        value = self._read(address, "bytes", b"\x00" * length)
        if isinstance(value, str):
            return value.encode("utf-8")
        return bytes(value)

    def write_float(self, address: int, value: float) -> None:
        self.writes.append(WriteRecord(address, "float", float(value)))

    def write_byte(self, address: int, value: int) -> None:
        self.writes.append(WriteRecord(address, "byte", int(value)))
