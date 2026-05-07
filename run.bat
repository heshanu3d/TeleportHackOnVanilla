@echo off
REM ============================================================
REM TeleportHack - one-click installer + launcher for Windows.
REM
REM Usage:
REM   - Double-click this file in Explorer, OR
REM   - Run from cmd.exe / PowerShell.
REM
REM What it does:
REM   1. Locates Python (uses PYTHON env var if set, else "python").
REM   2. Re-installs the project in editable mode with windows + dev
REM      extras, so any code change in win\ is picked up immediately.
REM   3. Launches the GUI via "python -m teleport_hack".
REM
REM Pass any arguments to this .bat and they are forwarded to
REM teleport-hack, e.g.: run.bat --version 1.12.1 --log-level DEBUG
REM ============================================================

setlocal enableextensions
pushd "%~dp0"

if not defined PYTHON set "PYTHON=python"

"%PYTHON%" --version >nul 2>&1
if errorlevel 1 goto :no_python

echo === Installing teleport-hack (editable) ===
"%PYTHON%" -m pip install -e "win[windows,dev]"
if errorlevel 1 goto :pip_failed

echo.
echo === Launching teleport-hack ===
"%PYTHON%" -m teleport_hack %*
set "EXITCODE=%ERRORLEVEL%"
goto :end

:no_python
echo [ERROR] Python not found. Set the PYTHON env var to the full
echo         path of python.exe, for example:
echo             set PYTHON=D:\Python3_10\python.exe
echo         then re-run this script.
set "EXITCODE=1"
goto :end

:pip_failed
echo [ERROR] pip install failed. See the messages above.
set "EXITCODE=1"
goto :end

:end
popd
echo.
echo (exit code: %EXITCODE%)
pause
endlocal
