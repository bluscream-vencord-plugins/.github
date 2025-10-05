@ECHO OFF
setlocal enabledelayedexpansion

@REM <region> Parameter Setup
set "SKIP_GIT=false"
if "%~1"=="/nogit" set "SKIP_GIT=true"
set "DEV=false"
if "%~1"=="/dev" set "DEV=true"
@REM </region>

@REM <region> Variable Initialization
for %%I in ("%CD%") do set "clientname=%%~nxI"
echo Starting %clientname% update process...
set "sourcefolder=%CD%\src\"
set "userpluginsfolder=%sourcefolder%userplugins\"
echo %userpluginsfolder%
@REM </region>

@REM <region> Git Operations
if "%SKIP_GIT%"=="false" (
    echo Updating git repository...
    git stash push -m "Auto-stash before update"
    git fetch
    git pull --recurse-submodules
    git submodule update --init --recursive
    echo Updating user plugins...
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
@REM </region>

@REM <region> Package Management
@REM pnpm add -g @pnpm/exe
echo Updating pnpm...
call pnpm self-update
echo pnpm self-update completed, continuing...
echo Installing dependencies...
pnpm install --frozen-lockfile
@REM </region>

@REM <region> Build Process
if "%DEV%"=="true" (
    echo Building in development mode (watch mode)...
    pnpm build --watch
) else (
    echo Building %clientname%...
    pnpm build
    echo Stopping Discord...
    taskkill /f /im Discord.exe
)
@REM </region>

@REM <region> Injection and Startup
echo Injecting %clientname%...
pnpm inject -install-openasar -branch stable
if "%DEV%"=="false" (
    echo Starting Discord...
    start "" "%LOCALAPPDATA%\Discord\Update.exe" --processStart Discord.exe
)
echo Update process completed!
@REM </region>
