# TeleportHack (Python/Qt port)

Cross-platform Python/PySide6 reimplementation of the original AutoIt
*TeleportHack On Vanilla and WLK* project.

> **Disclaimer.** This software writes to the memory of a running game
> client. Using it on online servers will likely violate their terms of
> service. The authors do not endorse cheating on live servers; the code
> exists for private-server / educational use only.

---

## Features

| Capability                            | 1.12.1 | 1.12.3 | 3.3.5 | Linux |
| ------------------------------------- | :----: | :----: | :---: | :---: |
| Read / write player position          | ✔      | ✔      | ✔     | ✘     |
| Step-by-step (smooth) teleport        | ✔      | ✔      | ✔     | ✘     |
| AntiJump toggle                       | ✔      | ✔      | —     | ✘     |
| AutoLoot, PatchLoot, LuaUnlock        | ✔      | ✔      | —     | ✘     |
| Speed override                        | —      | —      | ✔     | ✘     |
| Favourites CRUD + categories          | ✔      | ✔      | ✔     | ✔     |
| Insert / Append / Edit / Delete rows  | ✔      | ✔      | ✔     | ✔     |
| Description search filter             | ✔      | ✔      | ✔     | ✔     |
| Import / Export / Merge favourites    | ✔      | ✔      | ✔     | ✔     |
| Multi-process panel + manual Attach   | ✔      | ✔      | ✔     | n/a   |
| Persisted settings (`settings.json`)  | ✔      | ✔      | ✔     | ✔     |
| Global hotkey teleport                | ✔      | ✔      | ✔     | ✔ (UI loads, hotkeys can register, but memory is read-only stubbed) |

The Qt UI runs on Windows, Linux and macOS. Memory operations require a
running 32-bit WoW client and are only implemented on Windows (via the
[`pymem`](https://pypi.org/project/pymem/) package).

---

## Install

```bash
cd win
python -m venv .venv
. .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install -e ".[dev]"  # add ",windows" on Windows machines
```

## Run

```bash
teleport-hack --version 3.3.5 --favlist favlist.fav --hotkeys hotkey.txt
```

CLI flags:

| Flag           | Default          | Meaning                              |
| -------------- | ---------------- | ------------------------------------ |
| `--version`    | from settings    | WoW client build (`1.12.1` / `1.12.3` / `3.3.5`) |
| `--favlist`    | from settings    | Path to the favourites file          |
| `--hotkeys`    | from settings    | Path to the hotkey config            |
| `--settings`   | `./settings.json`| Path to the persisted settings file  |
| `--pid`        | autodetect       | Attach to a specific WoW PID         |
| `--log-level`  | `INFO`           | `DEBUG` / `INFO` / `WARNING` / `ERROR` |

CLI flags always take precedence over `settings.json`. If neither is
provided, the defaults baked into `Settings()` are used (`3.3.5`,
`./favlist.fav`, `./hotkey.txt`).

## Settings file

`settings.json` lives next to the executable / current working directory
by default. It is created on first save and contains:

| Key                | Default          | Description |
| ------------------ | ---------------- | ----------- |
| `step_distance`    | `10.0`           | Yards per hop for the smooth-step teleport |
| `step_sleep_ms`    | `40`             | Delay between hops, milliseconds |
| `default_version`  | `"3.3.5"`        | Auto-selected WoW build at launch |
| `favlist_path`     | `"favlist.fav"`  | Default favourites file |
| `hotkey_path`      | `"hotkey.txt"`   | Default hotkey config |
| `last_category`    | `"所有"`         | Last selected category in the UI |

A corrupt or unreadable `settings.json` falls back to the in-code
defaults — it never raises.

## GUI quick reference

| Element                               | Behaviour |
| ------------------------------------- | --------- |
| Top combo                             | Switch favourites *category* (derived from text before first `-`) |
| Search box                            | Live substring filter on the *description* column |
| `Add` button                          | Append a new row at the end of the global list |
| `Insert ↑`                            | Insert a new row **before** the selected row, in the same category |
| `Append ↓`                            | Insert a new row **after** the selected row, in the same category |
| `Edit` / `Delete`                     | Modify or remove the selected row |
| `Teleport` button / hotkey            | Write the selected position to the game (smooth-step on Windows) |
| File ▸ Import (Replace / Merge)       | Load a `.fav` from disk; *Merge* skips exact duplicates |
| File ▸ Export                         | Save the current favourites to a chosen path |
| Settings ▸ Preferences                | Edit step distance / sleep / paths and persist to `settings.json` |
| Process panel                         | List running `WoW.exe` instances (PID + character name) and Attach |

## Project layout

```
win/
├── pyproject.toml
├── src/teleport_hack/
│   ├── domain/             # value objects, no dependencies
│   ├── infrastructure/     # OS / file / pymem / pynput adapters
│   ├── application/        # use-case services (teleport, favourites…)
│   └── presentation/       # PySide6 widgets
├── tests/unit/             # 76 unit tests, no Qt / no Windows needed
└── docs/                   # architecture / design / test plan
```

## Testing

```bash
cd win
pytest                   # runs all unit tests
pytest --cov=teleport_hack
```

See `docs/test-plan.md` for the full strategy.

## Documentation

* [`docs/architecture.md`](docs/architecture.md) — layered architecture,
  module boundaries, dependency rules.
* [`docs/design.md`](docs/design.md) — concrete design decisions
  (memory chains, axis swap, hotkey threading…).
* [`docs/test-plan.md`](docs/test-plan.md) — coverage matrix and how to
  run the suites.
