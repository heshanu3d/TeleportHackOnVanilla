@echo off
REM ============================================================
REM TeleportHack — one-click installer + launcher for Windows.
REM
REM Usage:
REM   * Double-click this file in Explorer, OR
REM   * Run from cmd.exe / PowerShell.
REM
REM What it does:
REM   1. Locates Python (uses %PYTHON% env var if set, else `python`).
REM   2. (Re)installs the project in editable mode with windows + dev
REM      extras, so any code change in win\ is picked up immediately.
REM   3. Launches the GUI via `python -m teleport_hack`.
REM
REM   Pass any arguments to this .bat and they will be forwarded to
REM   teleport-hack (e.g. `run.bat --version 1.12.1 --log-level DEBUG`).
REM ============================================================

setlocal enableextensions

REM --- Always run from the directory this script lives in ----------
pushd "%~dp0"

REM --- Pick a Python interpreter ------------------------------------
if not defined PYTHON set "PYTHON=python"

"%PYTHON%" --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found. Set the PYTHON env var to the full
    echo         path of python.exe, e.g.:
    echo             set PYTHON=D:\Python3_10\python.exe
    echo         then re-run this script.
    goto :end
)

echo === Installing teleport-hack (editable) ===
"%PYTHON%" -m pip install -e "win[windows,dev]"
if errorlevel 1 (
    echo [ERROR] pip install failed. See the messages above.
    goto :end
)

echo.
echo === Launching teleport-hack ===
"%PYTHON%" -m teleport_hack %*
set "EXITCODE=%ERRORLEVEL%"

:end
popd
REM Keep the window open when double-clicked from Explorer so the
REM user can read any error output.
echo.
echo (exit code: %EXITCODE%)
pause
endlocal
