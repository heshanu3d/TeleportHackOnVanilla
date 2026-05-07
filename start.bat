@echo off
REM ============================================================
REM TeleportHack - launch-only helper.
REM Runs "python -m teleport_hack" without re-installing. Use this
REM for the common case of "I edited code in win\, just launch it".
REM Pass any args; they are forwarded to teleport-hack:
REM     start.bat --version 1.12.1 --log-level DEBUG
REM ============================================================

setlocal enableextensions
pushd "%~dp0"

if not defined PYTHON set "PYTHON=python"

"%PYTHON%" --version >nul 2>&1
if errorlevel 1 goto :no_python

"%PYTHON%" -m teleport_hack %*
set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
    echo.
    echo [ERROR] teleport-hack exited with code %EXITCODE%.
    echo         If this is the first run, execute install.bat once first.
)
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
