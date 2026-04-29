"""Qt model wrapping :class:`FavouritesService` for a :class:`QTableView`."""

from __future__ import annotations

from typing import List, Optional

from PySide6.QtCore import (
    QAbstractTableModel,
    QModelIndex,
    QSortFilterProxyModel,
    Qt,
)

from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.domain.models import ALL_CATEGORY, TeleportPoint

_HEADERS = ("描述", "X", "Y", "Z")


class TeleportTableModel(QAbstractTableModel):
    def __init__(self, service: FavouritesService) -> None:
        super().__init__()
        self._service = service
        self._category = ALL_CATEGORY
        self._rows: List[TeleportPoint] = list(service.all_points)

    # ----------------------------------------------------------- public API

    @property
    def category(self) -> str:
        return self._category

    def set_category(self, name: str) -> None:
        self.beginResetModel()
        self._category = name
        self._rows = self._service.points_in_category(name)
        self.endResetModel()

    def reload(self) -> None:
        self.set_category(self._category)

    def point_at(self, row: int) -> Optional[TeleportPoint]:
        if 0 <= row < len(self._rows):
            return self._rows[row]
        return None

    # ----------------------------------------------------- Qt model overrides

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: B008
        return 0 if parent.isValid() else len(self._rows)

    def columnCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: B008
        return 0 if parent.isValid() else len(_HEADERS)

    def headerData(self, section: int, orientation: Qt.Orientation, role: int = Qt.DisplayRole):
        if role != Qt.DisplayRole:
            return None
        if orientation == Qt.Horizontal:
            return _HEADERS[section]
        return section + 1

    def data(self, index: QModelIndex, role: int = Qt.DisplayRole):
        if not index.isValid() or role != Qt.DisplayRole:
            return None
        point = self._rows[index.row()]
        col = index.column()
        if col == 0:
            return point.description
        return (point.position.x, point.position.y, point.position.z)[col - 1]


class DescriptionFilterProxy(QSortFilterProxyModel):
    """Substring filter on the description column (case-insensitive)."""

    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.setFilterKeyColumn(0)
