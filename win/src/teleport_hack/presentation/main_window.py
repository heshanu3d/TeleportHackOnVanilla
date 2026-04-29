"""Main Qt window — thin glue layer between widgets and services."""

from __future__ import annotations

import logging
from pathlib import Path
from typing import List, Optional, Tuple

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QAction, QKeySequence
from PySide6.QtWidgets import (
    QCheckBox,
    QComboBox,
    QFileDialog,
    QGroupBox,
    QHBoxLayout,
    QHeaderView,
    QLabel,
    QLineEdit,
    QListWidget,
    QListWidgetItem,
    QMainWindow,
    QMessageBox,
    QPlainTextEdit,
    QPushButton,
    QStatusBar,
    QTableView,
    QVBoxLayout,
    QWidget,
)

from teleport_hack.application.favourites_porter import FavouritesPorter
from teleport_hack.application.favourites_service import FavouritesService
from teleport_hack.application.feature_toggles import FeatureService
from teleport_hack.application.hotkey_service import HotkeyService
from teleport_hack.application.settings import Settings, SettingsRepository
from teleport_hack.application.teleport_service import StepConfig, TeleportService
from teleport_hack.domain.models import ALL_CATEGORY, Position, TeleportPoint
from teleport_hack.domain.versions import GameVersion
from teleport_hack.infrastructure.hotkey.manager import HotkeyManager
from teleport_hack.infrastructure.memory.factory import (
    create_backend,
    list_wow_processes,
    read_player_name,
)
from teleport_hack.infrastructure.memory.null_backend import NullBackend
from teleport_hack.infrastructure.repository.hotkey_config import HotkeyConfigRepository
from teleport_hack.presentation.settings_dialog import SettingsDialog
from teleport_hack.presentation.teleport_table_model import (
    DescriptionFilterProxy,
    TeleportTableModel,
)

log = logging.getLogger(__name__)


class MainWindow(QMainWindow):
    teleport_requested = Signal(Position)

    def __init__(
        self,
        favourites: FavouritesService,
        version: GameVersion,
        hotkey_config_path: Path,
        settings_repository: SettingsRepository,
        settings: Settings,
        pid: Optional[int],
        backend_error: Optional[str] = None,
    ) -> None:
        super().__init__()
        self.setWindowTitle(f"TeleportHack — WoW {version.name}")
        self.resize(680, 800)

        self._favourites = favourites
        self._version = version
        self._hotkey_config_path = hotkey_config_path
        self._settings_repo = settings_repository
        self._settings = settings
        self._step_enabled = False
        self._current_pid = pid

        # Backend & services
        self._backend = self._create_backend(pid, backend_error)
        self._teleport = TeleportService(self._backend, version)
        self._features = FeatureService(self._backend, version)
        self._porter = FavouritesPorter(self._favourites)
        self._hotkey_manager = HotkeyManager()
        self._hotkey_service = HotkeyService(
            self._hotkey_manager, favourites, self._on_hotkey_teleport
        )

        self._build_ui()
        self.teleport_requested.connect(self._do_teleport)
        self._reload_categories()
        self._reload_processes()
        self._reload_hotkeys()

        if backend_error:
            self._log(f"[warn] {backend_error}")

    # ---------------------------------------------------------- UI building

    def _build_ui(self) -> None:
        central = QWidget(self)
        self.setCentralWidget(central)
        root = QVBoxLayout(central)

        # Menu bar
        menu = self.menuBar()
        file_menu = menu.addMenu("&File")

        act_import = QAction("Import &Merge...", self)
        act_import.triggered.connect(self._import_merge)
        file_menu.addAction(act_import)

        act_import_replace = QAction("Import &Replace...", self)
        act_import_replace.triggered.connect(self._import_replace)
        file_menu.addAction(act_import_replace)

        act_export = QAction("&Export...", self)
        act_export.triggered.connect(self._export)
        file_menu.addAction(act_export)

        file_menu.addSeparator()

        act_settings = QAction("&Settings...", self)
        act_settings.triggered.connect(self._open_settings)
        file_menu.addAction(act_settings)

        file_menu.addSeparator()
        act_quit = QAction("&Quit", self)
        act_quit.setShortcut(QKeySequence.Quit)
        act_quit.triggered.connect(self.close)
        file_menu.addAction(act_quit)

        # Top row: category + search
        top_row = QHBoxLayout()
        self._category_combo = QComboBox()
        self._category_combo.currentTextChanged.connect(self._on_category_changed)
        top_row.addWidget(QLabel("分类:"))
        top_row.addWidget(self._category_combo, stretch=1)

        self._search_edit = QLineEdit()
        self._search_edit.setPlaceholderText("搜索描述...")
        self._search_edit.textChanged.connect(self._on_search_changed)
        top_row.addWidget(QLabel("搜索:"))
        top_row.addWidget(self._search_edit, stretch=1)
        root.addLayout(top_row)

        # Table + filter proxy
        self._model = TeleportTableModel(self._favourites)
        self._proxy = DescriptionFilterProxy()
        self._proxy.setSourceModel(self._model)
        self._table = QTableView()
        self._table.setModel(self._proxy)
        self._table.setSelectionBehavior(QTableView.SelectRows)
        self._table.setSelectionMode(QTableView.SingleSelection)
        self._table.doubleClicked.connect(lambda _idx: self._teleport_selected())
        self._table.selectionModel().selectionChanged.connect(self._on_row_selected)
        header = self._table.horizontalHeader()
        header.setSectionResizeMode(0, QHeaderView.Stretch)
        for c in (1, 2, 3):
            header.setSectionResizeMode(c, QHeaderView.ResizeToContents)
        root.addWidget(self._table, stretch=1)

        # Description input
        self._desc_edit = QLineEdit()
        self._desc_edit.setPlaceholderText("传送点描述（如：斯坦索姆-入口）")
        root.addWidget(self._desc_edit)

        # Toggles row
        toggles = QHBoxLayout()
        self._step_cb = QCheckBox("step-tp")
        self._step_cb.toggled.connect(self._on_step_toggled)
        toggles.addWidget(self._step_cb)

        self._anti_jump_btn = QPushButton("AntiJump")
        self._anti_jump_btn.clicked.connect(self._toggle_anti_jump)
        toggles.addWidget(self._anti_jump_btn)

        self._autoloot_btn = QPushButton("AutoLoot")
        self._autoloot_btn.clicked.connect(self._toggle_autoloot)
        toggles.addWidget(self._autoloot_btn)

        self._lua_btn = QPushButton("LuaUnlock")
        self._lua_btn.clicked.connect(self._toggle_lua)
        toggles.addWidget(self._lua_btn)
        root.addLayout(toggles)

        # CRUD row 1: positional (Insert/Append/Edit/Delete)
        crud1 = QHBoxLayout()
        for label, slot in (
            ("Insert ↑", self._insert_point),
            ("Append ↓", self._append_point),
            ("Edit", self._edit_point),
            ("Delete", self._delete_point),
        ):
            btn = QPushButton(label)
            btn.clicked.connect(slot)
            crud1.addWidget(btn)
        root.addLayout(crud1)

        # CRUD row 2: append-end / save / reload
        crud2 = QHBoxLayout()
        for label, slot in (
            ("Add (end)", self._add_point),
            ("Save", self._save),
            ("Reload", self._reload_all),
        ):
            btn = QPushButton(label)
            btn.clicked.connect(slot)
            crud2.addWidget(btn)
        root.addLayout(crud2)

        # Teleport button
        self._teleport_btn = QPushButton("Teleport (Enter)")
        self._teleport_btn.setMinimumHeight(40)
        self._teleport_btn.clicked.connect(self._teleport_selected)
        root.addWidget(self._teleport_btn)

        # Speed row
        speed_row = QHBoxLayout()
        speed_row.addWidget(QLabel("Speed:"))
        self._speed_edit = QLineEdit(str(self._settings.speed_value))
        self._speed_edit.setMaximumWidth(60)
        speed_row.addWidget(self._speed_edit)
        speed_btn = QPushButton("Apply")
        speed_btn.clicked.connect(self._apply_speed)
        speed_row.addWidget(speed_btn)
        speed_row.addStretch(1)
        root.addLayout(speed_row)

        # Process list group
        proc_group = QGroupBox("WoW 进程 (PID — 玩家)")
        proc_layout = QVBoxLayout(proc_group)
        self._proc_list = QListWidget()
        self._proc_list.itemDoubleClicked.connect(self._on_proc_double_clicked)
        proc_layout.addWidget(self._proc_list)
        proc_btn_row = QHBoxLayout()
        attach_btn = QPushButton("Attach")
        attach_btn.clicked.connect(self._attach_selected_proc)
        refresh_btn = QPushButton("Refresh")
        refresh_btn.clicked.connect(self._reload_processes)
        proc_btn_row.addWidget(attach_btn)
        proc_btn_row.addWidget(refresh_btn)
        proc_btn_row.addStretch(1)
        proc_layout.addLayout(proc_btn_row)
        root.addWidget(proc_group)

        # Log
        self._log_view = QPlainTextEdit()
        self._log_view.setReadOnly(True)
        self._log_view.setMaximumBlockCount(500)
        root.addWidget(self._log_view, stretch=1)

        self.setStatusBar(QStatusBar())

        # Enter key triggers teleport
        enter_action = QAction(self)
        enter_action.setShortcut(QKeySequence(Qt.Key_Return))
        enter_action.triggered.connect(self._teleport_selected)
        self.addAction(enter_action)

    # ---------------------------------------------------------- backend

    def _create_backend(self, pid: Optional[int], error: Optional[str]):
        if error or pid is None or pid == 0:
            return NullBackend(pid=pid or 0)
        try:
            return create_backend(pid)
        except Exception as exc:  # pragma: no cover
            log.exception("Failed to attach to PID %s", pid)
            QMessageBox.warning(self, "Memory backend", str(exc))
            return NullBackend(pid=0)

    def _reattach(self, pid: int) -> None:
        if pid == self._current_pid and self._backend.is_attached():
            return
        try:
            self._backend.close()
        except Exception:  # pragma: no cover
            pass
        try:
            self._backend = create_backend(pid)
        except Exception as exc:
            self._log(f"[error] attach to PID {pid} failed: {exc}")
            self._backend = NullBackend(pid=0)
            return
        self._current_pid = pid
        self._teleport = TeleportService(self._backend, self._version)
        self._features = FeatureService(self._backend, self._version)
        self._log(f"attached to PID {pid}")

    # ---------------------------------------------------------- categories

    def _reload_categories(self) -> None:
        self._category_combo.blockSignals(True)
        self._category_combo.clear()
        self._category_combo.addItem(ALL_CATEGORY)
        for name in self._favourites.category_names():
            self._category_combo.addItem(name)
        # Try restoring last category
        idx = self._category_combo.findText(self._settings.last_category)
        if idx >= 0:
            self._category_combo.setCurrentIndex(idx)
        self._category_combo.blockSignals(False)
        self._model.set_category(self._category_combo.currentText())

    def _on_category_changed(self, name: str) -> None:
        self._model.set_category(name)
        self._settings.last_category = name

    def _on_search_changed(self, text: str) -> None:
        self._proxy.setFilterFixedString(text)

    def _on_row_selected(self, *_args) -> None:
        point = self._current_point()
        if point is not None:
            self._desc_edit.setText(point.description)

    # ---------------------------------------------------------- teleport

    def _current_source_row(self) -> Optional[int]:
        rows = self._table.selectionModel().selectedRows()
        if not rows:
            return None
        return self._proxy.mapToSource(rows[0]).row()

    def _current_point(self) -> Optional[TeleportPoint]:
        row = self._current_source_row()
        if row is None:
            return None
        return self._model.point_at(row)

    def _teleport_selected(self) -> None:
        point = self._current_point()
        if point is None:
            return
        self.teleport_requested.emit(point.position)

    def _on_hotkey_teleport(self, pos: Position) -> None:
        # Hotkey callback runs in pynput thread → marshal to GUI thread.
        self.teleport_requested.emit(pos)

    def _do_teleport(self, pos: Position) -> None:
        if not self._backend.is_attached():
            self._log("Backend not attached, teleport skipped.")
            return
        try:
            if self._step_enabled:
                steps = self._teleport.teleport_step(
                    pos,
                    StepConfig(
                        distance_per_step=self._settings.step_distance,
                        sleep_between_steps=self._settings.step_sleep_ms / 1000.0,
                    ),
                )
                self._log(f"step-teleport done in {steps} steps -> {pos.as_tuple()}")
            else:
                self._teleport.write_position(pos)
                self._log(f"teleported to {pos.as_tuple()}")
        except Exception as exc:
            log.exception("Teleport failed")
            self._log(f"[error] teleport failed: {exc}")

    # ---------------------------------------------------------- toggles

    def _on_step_toggled(self, checked: bool) -> None:
        self._step_enabled = checked

    def _toggle_anti_jump(self) -> None:
        self._safe_toggle("anti-jump", self._features.toggle_anti_jump)

    def _toggle_autoloot(self) -> None:
        self._safe_toggle("autoloot", self._features.toggle_autoloot)

    def _toggle_lua(self) -> None:
        self._safe_toggle("lua-unlock", self._features.toggle_lua_unlock)

    def _safe_toggle(self, name: str, fn) -> None:
        try:
            now_on = fn()
            self._log(f"{name}: {'ON' if now_on else 'OFF'}")
        except Exception as exc:
            self._log(f"[error] {name}: {exc}")

    def _apply_speed(self) -> None:
        try:
            value = float(self._speed_edit.text())
        except ValueError:
            self._log("[error] speed must be a number")
            return
        try:
            self._features.set_speed(value)
            self._settings.speed_value = value
            self._log(f"speed set to {value}")
        except Exception as exc:
            self._log(f"[error] speed: {exc}")

    # ---------------------------------------------------------- CRUD

    def _read_position_or_warn(self) -> Optional[Position]:
        try:
            return self._teleport.read_position()
        except Exception as exc:
            self._log(f"[error] cannot read position: {exc}")
            return None

    def _new_point_from_inputs(self) -> Optional[TeleportPoint]:
        desc = self._desc_edit.text().strip()
        if not desc:
            self._log("[warn] description is empty")
            return None
        pos = self._read_position_or_warn()
        if pos is None:
            return None
        return TeleportPoint(desc, pos)

    def _add_point(self) -> None:
        pt = self._new_point_from_inputs()
        if pt is None:
            return
        self._favourites.add(pt)
        self._reload_categories()
        self._log(f"added {pt.description} @ {pt.position.as_tuple()}")

    def _insert_point(self) -> None:
        row = self._current_source_row()
        if row is None:
            self._log("[warn] no row selected for insert")
            return
        pt = self._new_point_from_inputs()
        if pt is None:
            return
        try:
            self._favourites.insert_in_category(self._model.category, row, pt)
        except IndexError as exc:
            self._log(f"[error] {exc}")
            return
        self._reload_categories()
        self._log(f"inserted {pt.description} before row {row}")

    def _append_point(self) -> None:
        row = self._current_source_row()
        if row is None:
            self._log("[warn] no row selected for append")
            return
        pt = self._new_point_from_inputs()
        if pt is None:
            return
        try:
            self._favourites.append_in_category(self._model.category, row, pt)
        except IndexError as exc:
            self._log(f"[error] {exc}")
            return
        self._reload_categories()
        self._log(f"appended {pt.description} after row {row}")

    def _edit_point(self) -> None:
        row = self._current_source_row()
        if row is None:
            return
        pos = self._read_position_or_warn()
        if pos is None:
            return
        new_point = TeleportPoint(self._desc_edit.text().strip(), pos)
        try:
            self._favourites.replace_in_category(self._model.category, row, new_point)
        except IndexError as exc:
            self._log(f"[error] {exc}")
            return
        self._model.reload()
        self._log(f"updated row {row}")

    def _delete_point(self) -> None:
        row = self._current_source_row()
        if row is None:
            return
        try:
            removed = self._favourites.delete_in_category(self._model.category, row)
        except IndexError as exc:
            self._log(f"[error] {exc}")
            return
        self._model.reload()
        self._log(f"deleted {removed.description}")

    def _save(self) -> None:
        try:
            n = self._favourites.save()
            self._log(f"saved {n} points")
        except OSError as exc:
            self._log(f"[error] save failed: {exc}")

    def _reload_all(self) -> None:
        self._favourites.reload()
        self._reload_categories()
        self._reload_processes()
        self._reload_hotkeys()
        self._log("reloaded favourites + processes + hotkeys")

    # ---------------------------------------------------------- import/export

    def _export(self) -> None:
        target, _ = QFileDialog.getSaveFileName(
            self, "Export favourites", "favlist_export.fav",
            "Favlist (*.fav);;All files (*)",
        )
        if not target:
            return
        n = self._porter.export_to(target)
        self._log(f"exported {n} points to {target}")

    def _import_replace(self) -> None:
        source, _ = QFileDialog.getOpenFileName(
            self, "Import (replace) favourites", "",
            "Favlist (*.fav);;All files (*)",
        )
        if not source:
            return
        if QMessageBox.warning(
            self, "Replace favourites",
            "This will discard the current favourites in memory. Continue?",
            QMessageBox.Yes | QMessageBox.No, QMessageBox.No,
        ) != QMessageBox.Yes:
            return
        n = self._porter.import_replace(source)
        self._reload_categories()
        self._log(f"imported {n} points (replaced)")

    def _import_merge(self) -> None:
        source, _ = QFileDialog.getOpenFileName(
            self, "Import (merge) favourites", "",
            "Favlist (*.fav);;All files (*)",
        )
        if not source:
            return
        report = self._porter.import_merge(source)
        self._reload_categories()
        self._log(
            f"merged {report.added} new, skipped {report.skipped_duplicates} duplicates"
        )

    # ---------------------------------------------------------- settings

    def _open_settings(self) -> None:
        dlg = SettingsDialog(self._settings, self)
        if dlg.exec() == SettingsDialog.Accepted:
            self._settings = dlg.settings()
            try:
                self._settings_repo.save(self._settings)
                self._log("settings saved")
            except OSError as exc:
                self._log(f"[error] settings save failed: {exc}")

    # ---------------------------------------------------------- processes

    def _reload_processes(self) -> None:
        self._proc_list.clear()
        procs: List[Tuple[int, str]] = []
        try:
            procs = list_wow_processes(self._version.executable)
        except Exception as exc:
            self._log(f"[warn] process list failed: {exc}")
            return
        for pid, name in procs:
            label = f"{pid} — {name}"
            player = self._player_name_for(pid)
            if player:
                label += f" — {player}"
            item = QListWidgetItem(label)
            item.setData(Qt.UserRole, pid)
            if pid == self._current_pid:
                item.setText(label + "  ★")
            self._proc_list.addItem(item)
        if not procs:
            self._proc_list.addItem("(no WoW.exe found)")

    def _player_name_for(self, pid: int) -> Optional[str]:
        if not self._version.player_name:
            return None
        try:
            backend = create_backend(pid)
        except Exception:
            return None
        try:
            return read_player_name(backend, self._version.player_name)
        finally:
            try:
                backend.close()
            except Exception:  # pragma: no cover
                pass

    def _on_proc_double_clicked(self, item: QListWidgetItem) -> None:
        self._attach_selected_proc()

    def _attach_selected_proc(self) -> None:
        item = self._proc_list.currentItem()
        if item is None:
            return
        pid = item.data(Qt.UserRole)
        if not isinstance(pid, int):
            return
        self._reattach(pid)
        self._reload_processes()

    # ---------------------------------------------------------- hotkeys

    def _reload_hotkeys(self) -> None:
        repo = HotkeyConfigRepository(self._hotkey_config_path)
        try:
            bindings = repo.load()
        except OSError as exc:
            self._log(f"[warn] hotkey config: {exc}")
            return
        bound = self._hotkey_service.apply(bindings)
        self._log(f"registered {bound}/{len(bindings)} hotkeys")

    # ---------------------------------------------------------- shutdown

    def closeEvent(self, event) -> None:  # noqa: N802 (Qt naming)
        # Persist settings on close.
        try:
            self._settings_repo.save(self._settings)
        except Exception:
            pass
        try:
            self._hotkey_service.shutdown()
        except Exception:
            pass
        try:
            self._backend.close()
        except Exception:
            pass
        super().closeEvent(event)

    # ---------------------------------------------------------- helpers

    def _log(self, message: str) -> None:
        self._log_view.appendPlainText(message)
        log.info(message)
