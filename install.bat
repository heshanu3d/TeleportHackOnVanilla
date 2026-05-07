@echo off
REM ============================================================
REM TeleportHack - install-only helper.
REM Runs "pip install -e win[windows,dev]" and exits. Use this
REM after pulling new dependencies in pyproject.toml; for normal
REM day-to-day code edits no re-install is needed (editable mode).
REM ============================================================

setlocal enableextensions
pushd "%~dp0"

if not defined PYTHON set "PYTHON=python"

"%PYTHON%" --version >nul 2>&1
if errorlevel 1 goto :no_python

echo === Installing teleport-hack (editable, with windows + dev extras) ===
"%PYTHON%" -m pip install -e "win[windows,dev]"
set "EXITCODE=%ERRORLEVEL%"
goto :end

:no_python
echo [ERROR] Python not found. Set PYTHON=full\path\to\python.exe
set "EXITCODE=1"
goto :end

:end
popd
echo.
echo (exit code: %EXITCODE%)
pause
endlocal
