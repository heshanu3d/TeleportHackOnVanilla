"""Cross-platform global hotkey listener built on ``pynput``.

The AutoIt source uses HotKeySet with the ``+^!`` modifier prefix scheme.
We translate those combos into pynput's ``<ctrl>+<alt>+1`` syntax.

The manager runs the pynput listener in a background thread so it never
blocks the Qt event loop. It is safe to register/unregister callbacks at
runtime — the listener is restarted transparently.
"""

from __future__ import annotations

import logging
import threading
from typing import Callable, Dict, Optional

from teleport_hack.domain.models import Modifier

log = logging.getLogger(__name__)


_MOD_TO_PYNPUT = {
    Modifier.CTRL: "<ctrl>",
    Modifier.ALT: "<alt>",
    Modifier.SHIFT: "<shift>",
}


def parse_combo(raw: str) -> str:
    """Translate ``"^!1"`` -> ``"<ctrl>+<alt>+1"`` (pynput syntax)."""
    mods, key = Modifier.parse_prefix(raw)
    parts = [_MOD_TO_PYNPUT[m] for m in (Modifier.CTRL, Modifier.ALT, Modifier.SHIFT)
             if m in mods]
    if not key:
        raise ValueError(f"Hotkey combo missing key part: {raw!r}")
    parts.append(key.lower())
    return "+".join(parts)


class HotkeyManager:
    """Owns a single pynput :class:`GlobalHotKeys` listener."""

    def __init__(self) -> None:
        self._bindings: Dict[str, Callable[[], None]] = {}
        self._lock = threading.Lock()
        self._listener: Optional[object] = None

    # -------------------------------------------------------------- mutating
    def register(self, raw_combo: str, callback: Callable[[], None]) -> None:
        try:
            combo = parse_combo(raw_combo)
        except ValueError:
            log.warning("Skipping invalid hotkey combo: %r", raw_combo)
            return
        with self._lock:
            self._bindings[combo] = callback
            self._restart_locked()

    def unregister(self, raw_combo: str) -> None:
        try:
            combo = parse_combo(raw_combo)
        except ValueError:
            return
        with self._lock:
            if self._bindings.pop(combo, None) is not None:
                self._restart_locked()

    def clear(self) -> None:
        with self._lock:
            self._bindings.clear()
            self._stop_locked()

    # --------------------------------------------------------------- runtime
    def start(self) -> None:
        with self._lock:
            self._restart_locked()

    def stop(self) -> None:
        with self._lock:
            self._stop_locked()

    # -------------------------------------------------------------- internal
    def _restart_locked(self) -> None:
        self._stop_locked()
        if not self._bindings:
            return
        try:  # local import keeps the module importable without pynput
            from pynput import keyboard  # type: ignore
        except ImportError:
            log.warning("pynput not available — global hotkeys disabled.")
            return
        listener = keyboard.GlobalHotKeys(dict(self._bindings))
        listener.daemon = True
        listener.start()
        self._listener = listener

    def _stop_locked(self) -> None:
        listener = self._listener
        self._listener = None
        if listener is not None:
            try:
                listener.stop()  # type: ignore[attr-defined]
            except Exception:  # pragma: no cover
                log.exception("Failed to stop hotkey listener")

    @property
    def active_combos(self) -> tuple[str, ...]:
        with self._lock:
            return tuple(self._bindings)
