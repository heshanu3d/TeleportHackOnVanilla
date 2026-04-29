# Test Plan

## Goals

1. **100 % unit-test coverage of the pure logic layers** (`domain` +
   `application` + cross-platform `infrastructure.repository`).
2. Verify behaviour parity with the original AutoIt code for:
   * file format parsing (single + 4-line),
   * hotkey combo translation,
   * pointer-chain / axis-swap teleport math,
   * reversible byte-patch toggling,
   * category bucketing.
3. Stay green on Linux CI (no Windows binaries, no Qt event loop).

## Layered strategy

| Layer            | Test type                  | Notes                            |
| ---------------- | -------------------------- | -------------------------------- |
| `domain`         | Pure unit tests            | No mocks, no I/O                 |
| `infrastructure.repository` | Filesystem unit tests | `tmp_path` fixture        |
| `infrastructure.memory.null_backend` | Unit tests       | Used as a fixture for the next layer |
| `infrastructure.memory.pymem_backend` | **Manual** on Windows | Excluded from CI; would require a running game |
| `infrastructure.hotkey.manager` | Unit (parse_combo) + smoke | Listener I/O is excluded |
| `application/*`  | Unit tests with `NullBackend` | Full coverage              |
| `presentation`   | Manual / `pytest-qt` smoke | Out of scope for default CI |

## Test files & coverage matrix

| File                                  | Module under test                     | Cases |
| ------------------------------------- | ------------------------------------- | ----- |
| `tests/unit/test_domain_models.py`    | `domain.models`                       | 13 |
| `tests/unit/test_versions.py`         | `domain.versions`                     | 5  |
| `tests/unit/test_favlist_repository.py` | `infrastructure.repository.favlist` | 5  |
| `tests/unit/test_hotkey_repository.py` | `infrastructure.repository.hotkey_config` | 3 |
| `tests/unit/test_player_name.py`      | `infrastructure.memory.factory.read_player_name` | 4 |
| `tests/unit/test_favourites_service.py` | `application.favourites_service`    | 13 |
| `tests/unit/test_favourites_porter.py`| `application.favourites_porter`       | 5  |
| `tests/unit/test_settings.py`         | `application.settings`                | 6  |
| `tests/unit/test_teleport_service.py` | `application.teleport_service`        | 7  |
| `tests/unit/test_feature_toggles.py`  | `application.feature_toggles`         | 9  |
| `tests/unit/test_hotkey_service.py`   | `application.hotkey_service` + `infrastructure.hotkey.manager` (parser only) | 8 |

**Total: 76 unit tests**, exit code 0 in `0.14s` on a developer
laptop.

## Parity tests called out

| Original AutoIt behaviour                                        | Test |
| ---------------------------------------------------------------- | ---- |
| `1.12.1` returns `[Y, X, Z]` from `ReadPosition`                  | `test_vanilla_read_swaps_for_1_12_x` |
| `WritePosition($y, $x, $z)` in 1.12.x — engine swap                | `test_vanilla_write_walks_offset_chain_per_axis` |
| 3.3.5 pointer chain `static→+0x34→+0x24`                          | `test_335_read_position_walks_pointer_chain`, `test_335_write_swaps_x_and_y` |
| `AntiJump`: 0x75↔0xEB toggle + gravity 0/-7                      | `test_anti_jump_off_to_on`, `test_anti_jump_on_to_off` |
| `Autoloot`: `74 10` ↔ `90 90`                                     | `test_autoloot_off_to_on_writes_two_nops`, `test_autoloot_on_to_off` |
| `LuaUnlock`: 6-byte signature swap                                | `test_lua_unlock_off_to_on` |
| `GlobalSpeedSet` walks 3.3.5 pointer chain                        | `test_set_speed_walks_pointer_chain_on_335` |
| Single-line `desc#x#y#z` parsing                                  | `test_load_single_line_format` |
| Legacy 4-line-per-record fallback                                 | `test_load_legacy_4_line_format` |
| Category derived from substring before first `-`                  | `test_category_extracts_prefix_before_dash` |
| `+^!` modifier-prefix → pynput translation                       | `TestParseCombo` (5 cases) |
| Hotkey binding to a missing point is silently dropped             | `test_hotkey_service_binds_known_points` |
| Step teleport divides distance into N hops                        | `test_teleport_step_writes_n_intermediate_positions` |
| Insert before / append after selected row stays inside category   | `test_insert_in_category_uses_global_index`, `test_append_in_category_inserts_after_row` |
| Export round-trips current favourites                             | `test_export_writes_current_points` |
| Import-replace swaps the entire list                              | `test_import_replace_swaps_contents` |
| Import-merge skips exact duplicates, keeps near-duplicates        | `test_import_merge_adds_new_skips_duplicates` |
| Inline merge reports added vs. skipped counts                     | `test_merge_points_inline` |
| `settings.json` round-trip and corrupt-file fallback              | `test_round_trip`, `test_load_corrupt_returns_defaults` |
| Unknown settings keys ignored without raising                     | `test_load_unknown_keys_ignored` |
| `read_player_name` trims at NUL and decodes UTF-8 / Chinese       | `test_decodes_utf8_and_trims_at_nul`, `test_handles_chinese_player_name` |

## Running the tests

```bash
cd win
pip install -e ".[dev]"
pytest                          # default: unit tests
pytest --cov=teleport_hack -q   # with coverage
pytest -k teleport              # filter by test name
```

For a coverage report:

```bash
pytest --cov=teleport_hack --cov-report=html
xdg-open htmlcov/index.html
```

## Continuous integration outline

The test suite is designed for the following minimal GitHub Actions
matrix (left as a future task):

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    python: ['3.9', '3.11', '3.12']
steps:
  - uses: actions/checkout@v4
  - uses: actions/setup-python@v5
    with: { python-version: ${{ matrix.python }} }
  - run: pip install -e "./win[dev]"
  - run: pytest win/tests
```

`pymem` is intentionally excluded from the dev extras to keep the
Linux job hermetic; the Windows job can add `pip install pymem` if
hardware-in-the-loop testing is desired.

## Out-of-scope (manual verification)

The following items cannot be exercised in CI and require a manual
smoke test on a Windows host with a running WoW client:

1. `PymemBackend.read_*` / `write_*` against a real PID.
2. `pynput.GlobalHotKeys` actually capturing OS-level keypresses.
3. PySide6 main window rendering, table sort, log throttling.
4. Multi-window layout with multiple WoW clients (the original "sync"
   mode). The current port deliberately starts with single-client
   support; multi-client is a clean extension by holding a list of
   `MemoryBackend` instances inside `TeleportService`.

A short manual checklist is provided in `README.md` under "Run".
