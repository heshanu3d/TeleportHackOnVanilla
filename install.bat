@echo off
setlocal EnableExtensions EnableDelayedExpansion
pushd "%~dp0" || exit /b 1

set "EXITCODE=1"
set "BUILD_DIR=%CD%\build"
set "DEST=%~1"
if not defined DEST if exist ".install.ini" (
    set "IN_INSTALL_SECTION="
    for /f "usebackq tokens=1,* delims==" %%K in (".install.ini") do (
        if /i "%%K"=="[install]" set "IN_INSTALL_SECTION=1"
        if defined IN_INSTALL_SECTION if /i "%%K"=="path" set "DEST=%%L"
    )
)
if not exist "!BUILD_DIR!\version.txt" (
    echo [ERROR] No build found. Run build.bat first.
    goto :done
)
set /p "VERSION=" < "!BUILD_DIR!\version.txt"
if not defined VERSION goto :missing_build
for %%V in (1.12.1 1.12.3 3.3.5) do (
    if not exist "!BUILD_DIR!\Teleportors-%%V-!VERSION!.exe" goto :missing_build
)
if not defined DEST (
    echo No install path configured; release files are already in !BUILD_DIR!.
    set "EXITCODE=0"
    goto :done
)
if not exist "!DEST!" mkdir "!DEST!" || goto :done
for %%D in ("!DEST!\.") do set "DEST_FULL=%%~fD"
if /i "!DEST_FULL!"=="!BUILD_DIR!" (
    echo Release files are already in !BUILD_DIR!.
    set "EXITCODE=0"
    goto :done
)
for %%V in (1.12.1 1.12.3 3.3.5) do (
    copy /Y "!BUILD_DIR!\Teleportors-%%V-!VERSION!.exe" "!DEST!\" >nul || goto :done
)
for %%F in (favlist.fav hotkey.txt) do (
    if exist "!BUILD_DIR!\%%F" if not exist "!DEST!\%%F" (
        copy "!BUILD_DIR!\%%F" "!DEST!\%%F" >nul || goto :done
    )
)
echo Installed !VERSION! to !DEST!
set "EXITCODE=0"
goto :done

:missing_build
echo [ERROR] Build is incomplete. Run build.bat first.
:done
popd
endlocal & exit /b %EXITCODE%
