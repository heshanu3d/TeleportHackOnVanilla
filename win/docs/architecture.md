# Architecture

The Python port follows a strict **four-layer onion architecture**.
Dependencies only flow inward — outer layers may import inner layers,
never the reverse.

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation        teleport_hack.presentation              │
│   PySide6 widgets, Qt models, app entry point.              │
├─────────────────────────────────────────────────────────────┤
│ Application         teleport_hack.application               │
│   Use-case services (TeleportService, FeatureService,       │
│   FavouritesService, HotkeyService).                        │
├─────────────────────────────────────────────────────────────┤
│ Infrastructure      teleport_hack.infrastructure            │
│   OS-facing adapters: file repos, pymem, pynput.            │
├─────────────────────────────────────────────────────────────┤
│ Domain              teleport_hack.domain                    │
│   Pure value objects: Position, TeleportPoint, GameVersion. │
└─────────────────────────────────────────────────────────────┘
```

## Layer responsibilities

### Domain (`teleport_hack.domain`)
* Pure Python, **no** I/O, no third-party imports.
* Holds business invariants: `TeleportPoint`, `Position`,
  `Category`, `HotkeyBinding`, `Modifier`, `GameVersion`.
* Memory layouts for every supported WoW client live here as immutable
  `GameVersion` dataclasses (`versions.py`).

### Infrastructure (`teleport_hack.infrastructure`)
Three sub-packages, one adapter family each:

| Package             | Adapter            | Talks to                    |
| ------------------- | ------------------ | --------------------------- |
| `repository.favlist`| `FavlistRepository`| filesystem (`favlist.fav`)  |
| `repository.hotkey_config` | `HotkeyConfigRepository` | filesystem (`hotkey.txt`) |
| `memory.pymem_backend` | `PymemBackend`  | Windows kernel via `pymem`  |
| `memory.null_backend`  | `NullBackend`   | nothing (test/Linux stub)   |
| `memory.factory`    | `read_player_name`, `list_wow_processes` | psutil enumeration + UTF-8/NUL-terminated string read |
| `hotkey.manager`    | `HotkeyManager`    | OS keyboard via `pynput`    |

The `MemoryBackend` Protocol (`infrastructure.memory.backend`) decouples
the application layer from the underlying OS API.

### Application (`teleport_hack.application`)
Stateless (or thin-state) services that orchestrate domain objects via
infrastructure ports:

* **`TeleportService`** — pointer-chain resolution, axis swap, smooth
  step-teleport.
* **`FeatureService`** — toggle reversible byte patches (anti-jump,
  autoloot, patch-loot, lua-unlock) and write the speed value.
* **`FavouritesService`** — CRUD over the in-memory favourites,
  category-aware (`insert_in_category` / `append_in_category` translate
  per-category visible row indices to global list indices), persist via
  `FavlistRepository`.
* **`FavouritesPorter`** — import (replace / merge) and export
  favourites files; `MergeReport` reports added vs. duplicate rows
  (signature = `(description, x, y, z)`).
* **`HotkeyService`** — bind hotkey combos to teleport callbacks.
* **`Settings` / `SettingsRepository`** — JSON-backed user preferences
  (step distance / sleep, default version, favlist + hotkey paths,
  last-selected category). Corrupt or missing files fall back to the
  in-code defaults; unknown keys are ignored.

### Presentation (`teleport_hack.presentation`)
* `app.run` — argparse + `SettingsRepository` load + dependency wiring
  + Qt `exec()` loop. CLI flags override `settings.json`.
* `MainWindow` — owns the services; renders the favourites table,
  search box, Insert/Append/Edit/Delete buttons, Process panel
  (list + Attach + Refresh), File menu (Import Replace / Import Merge
  / Export) and Settings menu (Preferences).
* `TeleportTableModel` — Qt model adapter over `FavouritesService`.
* `DescriptionFilterProxy` — `QSortFilterProxyModel` providing a
  case-insensitive substring filter on the description column.
* `SettingsDialog` — modal editor for the `Settings` dataclass.

The Qt thread is the only thread that talks to widgets; the
`HotkeyManager` runs on a daemon thread and dispatches to the GUI via
`Signal` (`MainWindow.teleport_requested`).

## Dependency graph

```
presentation ──► application ──► domain
      │                ▲
      ▼                │
infrastructure ────────┘
```

Both `presentation` and `application` depend on `infrastructure`, but
only via Protocol-typed parameters — this is what makes the application
layer fully unit-testable with `NullBackend`.

## Cross-platform strategy

| Concern              | Windows                  | Linux / macOS             |
| -------------------- | ------------------------ | ------------------------- |
| GUI                  | PySide6                  | PySide6                   |
| Process memory       | `PymemBackend`           | `NullBackend` (read-only) |
| Process enumeration  | `psutil` / `pymem`       | returns `[]`              |
| Global hotkeys       | `pynput.GlobalHotKeys`   | `pynput.GlobalHotKeys`    |
| Favourites file I/O  | UTF-8 stdlib             | UTF-8 stdlib              |

`infrastructure.memory.factory.create_backend(pid)` is the single
platform check; everything else is platform-agnostic.

## Threading model

```
Qt main thread          pynput listener thread
──────────────          ──────────────────────
MainWindow              HotkeyManager
   │                          │
   │  Signal teleport_requested  ◄──── callback fires
   ▼                          │
TeleportService.write_position
   │
   ▼
PymemBackend (blocking syscalls)
```

All memory writes happen on the Qt main thread; the listener thread
only marshals a `Position` payload via `Qt.QueuedConnection`.
