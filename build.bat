@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0" || exit /b 1

set "EXITCODE=1"
set "BUILD_DIR=%CD%\build"
set "COMPILER=%AUTOIT_HOME%\Aut2Exe\Aut2exe.exe"
if not defined AUTOIT_HOME set "COMPILER=%ProgramFiles(x86)%\AutoIt3\Aut2Exe\Aut2exe.exe"
if not exist "!COMPILER!" if not defined AUTOIT_HOME set "COMPILER=%ProgramFiles%\AutoIt3\Aut2Exe\Aut2exe.exe"
if not exist "!COMPILER!" if not defined AUTOIT_HOME (
    for /f "tokens=1,2,*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\AutoItv3" /v UninstallString 2^>nul') do (
        if /i "%%A"=="UninstallString" for %%I in ("%%C") do set "COMPILER=%%~dpIAut2Exe\Aut2exe.exe"
    )
)
if not exist "!COMPILER!" if not defined AUTOIT_HOME (
    for /f "tokens=1,2,*" %%A in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AutoItv3" /v UninstallString 2^>nul') do (
        if /i "%%A"=="UninstallString" for %%I in ("%%C") do set "COMPILER=%%~dpIAut2Exe\Aut2exe.exe"
    )
)
if not exist "!COMPILER!" (
    echo [ERROR] Aut2Exe not found in Program Files or the AutoIt registry entry.
    echo Set AUTOIT_HOME to the AutoIt3 installation directory.
    goto :done
)
where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Git is required to determine the release version.
    goto :done
)

for /f "delims=" %%T in ('git describe --tags --abbrev^=0 HEAD') do set "TAG=%%T"
if not defined TAG (
    echo [ERROR] No reachable version tag found.
    goto :done
)
set "SEMVER=!TAG!"
if /i "!SEMVER:~0,1!"=="v" set "SEMVER=!SEMVER:~1!"
for /f "tokens=1-4 delims=." %%A in ("!SEMVER!") do (
    set "MAJOR=%%A"
    set "MINOR=%%B"
    set "PATCH=%%C"
    set "EXTRA=%%D"
)
if not defined MAJOR goto :invalid_tag
if not defined MINOR goto :invalid_tag
if not defined PATCH goto :invalid_tag
if defined EXTRA goto :invalid_tag
for %%N in (MAJOR MINOR PATCH) do (
    echo(!%%N!| findstr /R "^[0-9][0-9]*$" >nul
    if errorlevel 1 goto :invalid_tag
)
for /f "delims=" %%H in ('git rev-parse HEAD') do set "HEAD_COMMIT=%%H"
for /f "delims=" %%H in ('git rev-list -n 1 "!TAG!"') do set "TAG_COMMIT=%%H"
if not defined HEAD_COMMIT goto :git_failed
if not defined TAG_COMMIT goto :git_failed
if "!HEAD_COMMIT!"=="!TAG_COMMIT!" (
    set "VERSION=v!SEMVER!"
) else (
    set /a NEXT_PATCH=PATCH+1
    if errorlevel 1 goto :invalid_tag
    set "VERSION=v!MAJOR!.!MINOR!.!NEXT_PATCH!rc"
)

if not exist "!BUILD_DIR!" mkdir "!BUILD_DIR!" || goto :done
echo Building !VERSION! with !COMPILER!
call :compile 1.12.1 || goto :done
call :compile 1.12.3 || goto :done
call :compile 3.3.5 || goto :done
copy /Y "favlist.fav" "!BUILD_DIR!\favlist.fav" >nul || goto :done
if exist "hotkey.txt" copy /Y "hotkey.txt" "!BUILD_DIR!\hotkey.txt" >nul || goto :done
>"!BUILD_DIR!\version.txt" echo(!VERSION!
echo Build complete: !BUILD_DIR!
set "EXITCODE=0"
goto :done

:compile
set "OUTPUT=!BUILD_DIR!\Teleportors-%~1-!VERSION!.exe"
echo Compiling main%~1.au3
"!COMPILER!" /in "main%~1.au3" /out "!OUTPUT!" /icon "icon.ico" /x86
if errorlevel 1 exit /b 1
if not exist "!OUTPUT!" exit /b 1
exit /b 0

:invalid_tag
echo [ERROR] Tag !TAG! must use MAJOR.MINOR.PATCH, optionally prefixed with v.
goto :done

:git_failed
echo [ERROR] Could not resolve HEAD or tag !TAG!.
:done
popd
endlocal & exit /b %EXITCODE%
