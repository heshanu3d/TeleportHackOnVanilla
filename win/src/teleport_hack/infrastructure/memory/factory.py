"""Platform-aware backend factory + WoW-process discovery."""

from __future__ import annotations

import sys
from typing import List, Optional, Tuple

from teleport_hack.infrastructure.memory.backend import MemoryBackend, MemoryError
from teleport_hack.infrastructure.memory.null_backend import NullBackend


def is_windows() -> bool:
    return sys.platform.startswith("win")


def create_backend(pid: int) -> MemoryBackend:
    """Return the right backend for the current platform."""
    if is_windows():
        from teleport_hack.infrastructure.memory.pymem_backend import PymemBackend
        return PymemBackend(pid)
    return NullBackend(pid=pid)


def list_wow_processes(executable: str = "WoW.exe") -> List[Tuple[int, str]]:
    """Find every running WoW process. Returns ``[(pid, name), ...]``.

    On non-Windows platforms returns an empty list.
    """
    if not is_windows():
        return []

    try:  # pragma: no cover - only on Windows
        import psutil  # type: ignore
    except ImportError:
        try:  # pymem ships psutil transitively
            from pymem.process import list_processes  # type: ignore
        except Exception as exc:  # pragma: no cover
            raise MemoryError("Cannot enumerate processes; install psutil.") from exc
        wanted = executable.lower()
        return [(p.th32ProcessID, p.szExeFile.decode()) for p in list_processes()
                if p.szExeFile.decode().lower() == wanted]

    wanted = executable.lower()  # pragma: no cover
    return [
        (proc.info["pid"], proc.info["name"])
        for proc in psutil.process_iter(["pid", "name"])
        if proc.info["name"] and proc.info["name"].lower() == wanted
    ]


def read_player_name(backend: MemoryBackend, address: int, length: int = 12) -> Optional[str]:
    """Read the null-terminated UTF-8 player name from memory.

    Returns ``None`` if the backend has no data (e.g. NullBackend) so the
    caller can decide whether to display a placeholder.
    """
    if not address:
        return None
    raw = backend.read_bytes(address, length)
    # Trim at first NUL.
    if b"\x00" in raw:
        raw = raw.split(b"\x00", 1)[0]
    if not raw or all(b == 0 for b in raw):
        return None
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        # Fall back to the GBK code page (the original AutoIt used the OEMCP).
        try:
            return raw.decode("gbk")
        except UnicodeDecodeError:
            return None
