"""Memory backends.

A backend exposes a tiny, type-safe surface for reading/writing primitive
values from the WoW process. Concrete implementations:

* :class:`PymemBackend` — Windows only, uses the third-party ``pymem`` package.
* :class:`NullBackend` — no-op stub used on non-Windows platforms and in tests.

The :func:`create_backend` factory selects the right implementation.
"""

from teleport_hack.infrastructure.memory.backend import MemoryBackend, MemoryError
from teleport_hack.infrastructure.memory.factory import (
    create_backend,
    list_wow_processes,
    read_player_name,
)
from teleport_hack.infrastructure.memory.null_backend import NullBackend

__all__ = [
    "MemoryBackend",
    "MemoryError",
    "NullBackend",
    "create_backend",
    "list_wow_processes",
    "read_player_name",
]
