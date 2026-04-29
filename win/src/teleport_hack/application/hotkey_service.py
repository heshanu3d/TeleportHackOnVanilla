"""Wire :class:`HotkeyManager` together with the favourites store."""

from __future__ import annotations

import logging
from typing import Callable, Iterable

from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.domain.models import HotkeyBinding, Position
from teleport_hack.infrastructure.hotkey.manager import HotkeyManager

log = logging.getLogger(__name__)

TeleportCallback = Callable[[Position], None]


class HotkeyService:
    """Bind every hotkey binding to a teleport callback."""

    def __init__(
        self,
        manager: HotkeyManager,
        favourites: FavouritesService,
        teleport_callback: TeleportCallback,
    ) -> None:
        self._manager = manager
        self._fav = favourites
        self._tp = teleport_callback

    def apply(self, bindings: Iterable[HotkeyBinding]) -> int:
        """Replace all current registrations. Returns the count actually bound."""
        self._manager.clear()
        bound = 0
        for binding in bindings:
            point = self._fav.find_by_name(binding.point_name)
            if point is None:
                log.warning("Hotkey %s: point %r not found", binding.raw_combo, binding.point_name)
                continue
            self._manager.register(binding.raw_combo, self._make_handler(point.position))
            bound += 1
        self._manager.start()
        return bound

    def shutdown(self) -> None:
        self._manager.clear()

    def _make_handler(self, position: Position) -> Callable[[], None]:
        cb = self._tp

        def _handler() -> None:
            try:
                cb(position)
            except Exception:
                log.exception("Teleport hotkey handler failed")
        return _handler
