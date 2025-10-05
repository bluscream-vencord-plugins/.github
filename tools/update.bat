@ECHO OFF
setlocal enabledelayedexpansion

@REM region Parameter Setup
set "SKIP_GIT=false"
if "%~1"=="/nogit" set "SKIP_GIT=true"
set "DEV=false"
if "%~1"=="/dev" set "DEV=true"
@REM endregion

@REM region Variable Initialization
for %%I in ("%CD%") do set "clientname=%%~nxI"
echo Starting %clientname% update process
set "sourcefolder=%CD%\src\"
set "userpluginsfolder=%sourcefolder%userplugins\"
set "discordname=Discord"
set "branch=stable"
echo %userpluginsfolder%
@REM endregion

@REM region Git Operations
if "%SKIP_GIT%"=="false" (
    echo Updating git repository
    git stash push -m "[%date% %time%] Auto-stash %clientname% before update"
    git fetch
    git pull --recurse-submodules
    git submodule update --init --recursive
    echo Updating user plugins
    for /d %%d in (%userpluginsfolder%\*) do (
        if exist "%%d\.git" (
            pushd "%%d"
            set "pluginname=%%~nxd"
            echo Updating user plugin: !pluginname!
            git stash push -m "[%date% %time%] Auto-stash !pluginname! before update"
            git fetch
            git pull
            popd
        )
    )
) else (
    echo Skipping git operations as /nogit was specified
)
@REM endregion

@REM region Package Management
@REM pnpm add -g @pnpm/exe
echo Updating pnpm
call pnpm self-update
echo pnpm self-update completed!
echo Installing dependencies
call pnpm install --frozen-lockfile
echo Dependencies installation completed!
@REM endregion

@REM region Build Process
if "%DEV%"=="true" (
    echo Building !clientname! in development mode
    pnpm build --watch
    echo Build completed
) else (
    echo Building !clientname! in production mode
    call pnpm build
    echo Build completed
    echo Stopping Discord
    call taskkill /f /im %discordname%.exe 2>nul
    if errorlevel 1 (
        echo Discord was not running
    ) else (
        echo Discord stopped successfully
    )
)
@REM endregion

@REM region Injection and Startup
echo Injecting !clientname!
call pnpm inject -install-openasar -branch %branch%
echo Injection completed
if "%DEV%"=="false" (
    echo Starting Discord
    start "" "%LOCALAPPDATA%\%discordname%\Update.exe" --processStart %discordname%.exe
)
echo Update process completed!
color 0a
@REM endregion
