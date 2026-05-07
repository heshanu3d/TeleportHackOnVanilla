# TeleportHack On Vanilla and WLK

Teleport hack for World of Warcraft clients **1.12.1, 1.12.3, 3.3.5**.

The original implementation lives in the AutoIt files at the repository
root (`main*.au3`, `hack.au3`, ...). A modern, cross-platform Python /
PySide6 port lives in [`win/`](win/) and ships with full unit tests and
documentation.

## Quick start (Windows)

Three batch files at the repository root cover the common workflows.
Double-click one in Explorer, or call it from `cmd.exe` / PowerShell:

| Script | What it does | When to use |
| ------ | ------------ | ----------- |
| `install.bat` | `pip install -e "win[windows,dev]"` only | After pulling new deps in `win/pyproject.toml` |
| `start.bat`   | `python -m teleport_hack` only           | Everyday: edited code in `win\` and want to run it |
| `run.bat`     | install **then** start                   | First run, or "I'm not sure if anything is installed" |

All three:

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

Because `pip install -e` is editable, you do **not** need to re-run
`install.bat` after editing files in `win\src\`.

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
