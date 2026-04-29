"""Modal dialog editing :class:`teleport_hack.application.Settings`."""

from __future__ import annotations

from PySide6.QtWidgets import (
    QCheckBox,
    QDialog,
    QDialogButtonBox,
    QDoubleSpinBox,
    QFormLayout,
    QLineEdit,
    QSpinBox,
    QVBoxLayout,
)

from teleport_hack.application.settings import Settings


class SettingsDialog(QDialog):
    def __init__(self, settings: Settings, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Settings")
        self.resize(360, 260)
        self._settings = Settings(**settings.to_dict())  # working copy

        layout = QVBoxLayout(self)
        form = QFormLayout()
        layout.addLayout(form)

        self._step_distance = QDoubleSpinBox()
        self._step_distance.setRange(0.1, 1000.0)
        self._step_distance.setDecimals(2)
        self._step_distance.setValue(self._settings.step_distance)
        form.addRow("Step distance", self._step_distance)

        self._step_sleep_ms = QSpinBox()
        self._step_sleep_ms.setRange(0, 5000)
        self._step_sleep_ms.setSuffix(" ms")
        self._step_sleep_ms.setValue(self._settings.step_sleep_ms)
        form.addRow("Step sleep", self._step_sleep_ms)

        self._fast_step = QCheckBox("Skip {Left}/{Right} taps after teleport")
        self._fast_step.setChecked(self._settings.fast_step)
        form.addRow("Fast step", self._fast_step)

        self._speed_value = QDoubleSpinBox()
        self._speed_value.setRange(0.1, 200.0)
        self._speed_value.setDecimals(2)
        self._speed_value.setValue(self._settings.speed_value)
        form.addRow("Default speed", self._speed_value)

        self._favlist_path = QLineEdit(self._settings.favlist_path)
        form.addRow("Favlist path", self._favlist_path)

        self._hotkey_path = QLineEdit(self._settings.hotkey_path)
        form.addRow("Hotkey path", self._hotkey_path)

        buttons = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    def settings(self) -> Settings:
        """Return the *edited* settings (only valid after ``exec()`` returns Accepted)."""
        return Settings(
            step_distance=self._step_distance.value(),
            step_sleep_ms=self._step_sleep_ms.value(),
            default_version=self._settings.default_version,
            favlist_path=self._favlist_path.text().strip() or "favlist.fav",
            hotkey_path=self._hotkey_path.text().strip() or "hotkey.txt",
            last_category=self._settings.last_category,
            speed_value=self._speed_value.value(),
            fast_step=self._fast_step.isChecked(),
        )
