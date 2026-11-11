# TeleportHack On Vanilla and WLK

Teleport hack for World of Warcraft clients **1.12.1, 1.12.3, 3.3.5**.

The original implementation lives in the AutoIt files at the repository
root (`main*.au3`, `hack.au3`, ...). A modern, cross-platform Python /
PySide6 port lives in [`win/`](win/) and ships with full unit tests and
documentation.

The AutoIt **设置** tab controls the WoW PID polling interval (1–3600 seconds,
default 30). Applying a new value saves it in `teleport_ui.ini` beside the
script/executable and restarts the polling timer. The **关于** tab lists the
author and release notes for each tag.

The AutoIt **分类设置** tab manages category groups and category membership.
Use Ctrl and Shift to select multiple categories for moving or reordering.
Assignments for categories absent from the current favourites file are kept.
The main page filters descriptions as you type; searches enter the history when
editing ends, and selecting a history entry restores it. **独立搜索** keeps a
separate search for each navigation category. Search history can be edited in
**设置**.

The **设置** tab also provides automatic saving after coordinate edits,
right-click teleport, light/dark themes, opacity, layout dimensions, and
individual coordinate-column visibility. These preferences and category
assignments are stored in teleport_preferences.ini beside the executable;
the existing PID timer stays in teleport_ui.ini. Hiding a column does not
remove its saved value. The Python/PySide6 application has its own settings
and does not share this AutoIt preferences file.

## AutoIt builds (Windows)

Run `build.bat` from any working directory. The tracked `.build.ini` contains
`[build]` / `sdk_path=D:\SDK\AutoIt3`; this SDK path takes precedence over
`AUTOIT_HOME`. If the configuration is absent or its path is empty, the script
falls back to `AUTOIT_HOME`, the standard AutoIt installation path, or the
AutoIt registry entry. Git is
required to read the most recent reachable tag. The output goes to `build\`:
three `Teleportors-<client>-<version>.exe` files, plus `favlist.fav` and
`hotkey.txt`. At the tagged commit `0.5.2`, the version is `v0.5.2`. On a
newer commit it is `v0.5.3rc` (the next patch number with `rc`). Uncommitted
changes do not alter the version.

The ignored `.install.ini` sets the default installation directory:
`[install]` / `path=D:\Game\wow_client\wow_tools\TeleportOnVanilla`. Use
`install.bat` to copy the current build there; an explicit directory argument
overrides the file. If the file or path is absent, the release files remain
in the project-root `build\` directory. Existing destination `favlist.fav`
and `hotkey.txt` are preserved. `build_and_install.bat` builds and then
installs using the same rule. For example:

```bat
build_and_install.bat
```

## Python quick start (Windows)

The Python port has two launch scripts at the repository root. Double-click
one in Explorer, or call it from `cmd.exe` / PowerShell:

| Script | What it does | When to use |
| ------ | ------------ | ----------- |
| `start.bat`   | `python -m teleport_hack` only           | Everyday: edited code in `win\` and want to run it |
| `run.bat`     | install **then** start                   | First run, or "I'm not sure if anything is installed" |

Both:

- Honour the `PYTHON` env var if `python` is not on `PATH`, e.g.
  `set PYTHON=D:\Python3_10\python.exe`.
- Use the script's own directory as CWD, regardless of where you invoke
  them from.
- Pause at the end so error output stays on screen when launched from
  Explorer.

`start.bat` and `run.bat` forward any extra arguments to
`teleport-hack`:

```
start.bat --version 1.12.1 --log-level DEBUG
run.bat   --pid 1234 --favlist D:\my\favlist.fav
```

Because `run.bat` installs in editable mode, later edits in `win\src\`
are picked up by `start.bat` without another install.

## See also

- [`win/README.md`](win/README.md) — full feature matrix, CLI flags,
  GUI walkthrough, and settings reference.
- [`win/docs/architecture.md`](win/docs/architecture.md) — onion
  architecture and dependency rules.
- [`win/docs/design.md`](win/docs/design.md) — concrete design
  decisions (memory chains, axis swap, hotkey threading, settings,
  import/export).
- [`win/docs/test-plan.md`](win/docs/test-plan.md) — test strategy
  and coverage matrix.
