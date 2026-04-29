# Design Notes

This document captures the non-obvious design decisions that came out of
porting the AutoIt original to Python.

## 1. Memory address resolution

WoW exposes the player position differently on every client build:

* **3.3.5 (WLK)** — pointer chain:
  `[StaticPlayer]→+0x34→+0x24→base + {pos_x, pos_y, pos_z}`
* **1.12.x (Vanilla)** — multi-level offset chain. Five hops, each
  computed independently per axis using the
  `DstXOffsetArray / DstYOffsetArray / DstZOffsetArray` triplets.

Both are encapsulated inside `TeleportService._resolve_player_base()`
and `_resolve_vanilla_write_addresses()`, so callers never see raw
addresses.

## 2. Axis swap

The original code does a confusing swap when calling `WritePosition`:

```autoit
If $version = "3.3.5" or $version = "1.12.1" Then
    WritePosition($y, $x, $z)
ElseIf $version = "1.12.3" Then
    WritePosition($y, $x, $z)
EndIf
```

In other words: in every supported version, the engine wants
`(engine_x = ui_y, engine_y = ui_x, engine_z = ui_z)` on write, and
returns the same swapped tuple on read for `1.12.1`. We normalise this
inside `TeleportService` so that the rest of the codebase works
exclusively with logical `(x, y, z)` order. The Qt UI never has to
think about axes.

## 3. Reversible byte patches

`FeatureService` implements a tiny pattern: every patch has two known
byte states (OFF and ON). The toggle:

1. reads the current bytes,
2. compares against both known patterns,
3. writes the *other* pattern,
4. raises `ValueError` if neither matches (instead of corrupting
   memory).

This mirrors the AutoIt `If $val = 0x75 ... ElseIf $val = 0xEB`
pattern but makes the failure path explicit. Tests cover all three
branches per feature.

## 4. Favourites file format

The AutoIt loader supported two formats:

```
desc#x#y#z              # canonical
desc \n x \n y \n z     # legacy 4-line per record
```

`FavlistRepository.load()` accepts both formats; `save()` always emits
the canonical single-line form. Therefore the file self-normalises on
the first save, but old user files keep working.

## 5. Categories

Categories are *derived*, not stored. We use the same rule as the
original: take the substring before the first `-`. Points without a
dash fall into `OTHER_CATEGORY` (`其他`).

This means:

* No need to migrate stored data to a new schema.
* Renaming a category is just a description rename.
* The synthetic `所有` (`ALL_CATEGORY`) shows everything.

`FavouritesService._global_index()` translates a per-category visible
row index back to a global list index, which is what enables the
"insert relative to current selection" semantics from the AutoIt UI.

## 6. Hotkey combo encoding

We keep the AutoIt `+^!` modifier-prefix syntax in user files because
it's terse and matches the existing `hotkey.txt`. Internally we
translate to pynput's
`<ctrl>+<alt>+1` form via `infrastructure.hotkey.parse_combo`.

| AutoIt char | Modifier | pynput token |
| ----------- | -------- | ------------ |
| `+`         | Shift    | `<shift>`    |
| `^`         | Ctrl     | `<ctrl>`     |
| `!`         | Alt      | `<alt>`      |

Single-letter keys are lowercased so `^A` matches `Ctrl+a`.

## 7. Backend abstraction

`MemoryBackend` is a `typing.Protocol`. This avoids inheritance
boilerplate and lets us treat the test stub (`NullBackend`) and the
real `PymemBackend` interchangeably.

Three benefits:

1. **Testability**: 100 % of `application/` is exercised in CI on
   Linux without any Windows process.
2. **Optional dependency**: `pymem` is in the `windows` extra; the
   package imports cleanly without it on Linux.
3. **Future-proofing**: adding a Wine backend later means writing one
   adapter that satisfies the protocol, with no other changes.

## 8. Threading

`HotkeyManager` owns a `pynput.keyboard.GlobalHotKeys` listener on a
daemon thread. Hotkey callbacks would normally run on that thread,
which is unsafe for Qt. We solve this with a `MainWindow.teleport_requested`
signal: the callback emits the position, Qt's auto-connection delivers
it on the main thread, and `_do_teleport` runs the memory write
serially with UI-driven teleports. No locks needed.

## 9. UI / model split

Even though the favourites are a flat in-memory list, we expose them
through a proper `QAbstractTableModel`. This:

* gives us cheap row insertions / deletions (no full repaint),
* makes per-column resize work with `QHeaderView.Stretch`,
* opens the door to sorting / filtering proxies later.

`TeleportTableModel.set_category()` is the single funnel for view
state changes; it always issues a `beginResetModel()/endResetModel()`
pair to keep selection state predictable.

## 10. Error reporting

The AutoIt code logs to a custom `Edit` widget. The Python port writes
to:

* `QPlainTextEdit` (`MainWindow._log_view`) for user-visible status.
* The standard `logging` module for stack traces (`--log-level DEBUG`
  on the CLI).

Errors raised by `FeatureService` / `TeleportService` are caught at the
UI boundary (`MainWindow._safe_toggle`, `_do_teleport`) and surfaced as
log lines, never as uncaught exceptions in the Qt loop.

## 11. Settings persistence

`Settings` is a frozen-style dataclass with sensible defaults; values
are persisted to `settings.json` via `SettingsRepository.save()`.

Design choices:

* **Location next to the executable**, not in `%APPDATA%` or
  `~/.config` — the user explicitly requested a portable layout that
  travels with the project folder.
* **Forgiving load**: missing file, corrupt JSON, or unknown keys all
  yield a valid `Settings()` instead of an exception. This makes the
  GUI bootstrap path crash-free on first run.
* **No schema migrations yet**: unknown keys are silently dropped.
  This is acceptable while the field set is small; a `version` field
  can be added when the first incompatible change ships.
* **CLI > settings > defaults** precedence is enforced in
  `presentation.app.run`. The settings file therefore acts as a
  defaults provider, never as a hard override.

## 12. Favourites import / export

`FavouritesPorter` is a thin orchestrator over `FavouritesService` and
`FavlistRepository`:

| Operation        | Behaviour |
| ---------------- | --------- |
| `export_to(path)`     | Writes the current in-memory list verbatim. |
| `import_replace(path)`| Loads the file and replaces the entire list. |
| `import_merge(path)`  | Appends rows whose `(description, x, y, z)` tuple is not already present; returns a `MergeReport` with `added` / `skipped_duplicates` counters. |
| `merge_points(iter)`  | Same dedup logic against an in-memory iterable, used by future "paste" / drag-drop flows. |

The signature deliberately includes the description so two distinct
landmarks at the same coordinates (e.g. an entry portal vs. an exit
portal) both survive a merge.

## 13. Description search filter

`DescriptionFilterProxy` is a `QSortFilterProxyModel` that overrides
`filterAcceptsRow` to do a case-insensitive substring match against the
description column. We chose a Qt proxy rather than a `set_category`
extension because:

* the proxy preserves the source model's selection / row-insert
  semantics,
* the search is purely a *view* concern and should not pollute the
  application service,
* future filters (e.g. coordinate range) can stack additional proxies
  without touching `FavouritesService`.

## 14. Process enumeration & player-name preview

`infrastructure.memory.factory.list_wow_processes()` uses `psutil` to
list every running `WoW.exe` (case-insensitive). For each PID,
`read_player_name(backend, address, length=12)` reads up to N bytes
from the version-specific player-name pointer, stops at the first NUL,
and decodes as UTF-8 with `errors="replace"`. The function returns
`None` for `address == 0` or all-zero buffers so the UI can render a
placeholder instead of an empty string.
