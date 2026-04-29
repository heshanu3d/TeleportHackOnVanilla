"""Windows implementation backed by the ``pymem`` package.

Only imported on Windows; the import of ``pymem`` is deferred so the rest
of the codebase remains importable on Linux/macOS for tests and UI work.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from teleport_hack.infrastructure.memory.backend import MemoryError

if TYPE_CHECKING:  # pragma: no cover
    import pymem  # noqa: F401


class PymemBackend:
    """Reads/writes a remote process via ``pymem``.

    On construction we attach to the given PID. :meth:`close` detaches.
    """

    def __init__(self, pid: int) -> None:
        try:
            import pymem  # local import: package is Windows-only
        except ImportError as exc:  # pragma: no cover - exercised on Windows
            raise MemoryError(
                "pymem is required on Windows; install with `pip install pymem`."
            ) from exc

        self.pid = pid
        try:
            self._pm = pymem.Pymem()
            self._pm.open_process_from_id(pid)
        except Exception as exc:  # pragma: no cover
            raise MemoryError(f"Failed to open process {pid}: {exc}") from exc

    # ------------------------------------------------------------------ life
    def is_attached(self) -> bool:
        return getattr(self._pm, "process_handle", None) is not None

    def close(self) -> None:
        try:
            self._pm.close_process()
        except Exception:  # pragma: no cover
            pass

    # ----------------------------------------------------------------- reads
    def read_float(self, address: int) -> float:  # pragma: no cover
        return float(self._pm.read_float(address))

    def read_uint32(self, address: int) -> int:  # pragma: no cover
        return int(self._pm.read_uint(address))

    def read_byte(self, address: int) -> int:  # pragma: no cover
        return int(self._pm.read_uchar(address))

    def read_pointer(self, address: int) -> int:  # pragma: no cover
        # WoW vanilla / wlk are 32-bit clients
        return int(self._pm.read_uint(address))

    def read_bytes(self, address: int, length: int) -> bytes:  # pragma: no cover
        return bytes(self._pm.read_bytes(address, length))

    # ---------------------------------------------------------------- writes
    def write_float(self, address: int, value: float) -> None:  # pragma: no cover
        self._pm.write_float(address, float(value))

    def write_byte(self, address: int, value: int) -> None:  # pragma: no cover
        self._pm.write_uchar(address, int(value) & 0xFF)
