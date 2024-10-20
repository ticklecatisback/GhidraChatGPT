@echo off
setlocal enabledelayedexpansion

set VERSION=11.1.3
set DOCKER_GHIDRA_IMG=ghidra-chatgpt:%VERSION%
set DOCKER_BUILD=0
set FORCE_BUILD=0
set DEV_BUILD=0
set GHIDRA_PATH=%GHIDRA_INSTALL_DIR%
set GHIDRA_MNT_DIR=/ghidra

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

:docker_build
echo [^+] Building the GhidraChatGPT Plugin >&2

docker images -q "%DOCKER_GHIDRA_IMG%" 2> nul
if %errorlevel% neq 0 if %FORCE_BUILD% equ 0 (
    docker build --build-arg UID=%UID% --build-arg GID=%GID% -t "%DOCKER_GHIDRA_IMG%" .
)

docker run -t --rm --user %UID%:%GID% --mount type=bind,source="%GHIDRA_PATH%",target="%GHIDRA_MNT_DIR%" --entrypoint /entry "%DOCKER_GHIDRA_IMG%"
goto :eof

:clean
rd /s /q ghidrachatgpt\build 2> nul
rd /s /q ghidrachatgpt\dist 2> nul
rd /s /q ghidrachatgpt\lib 2> nul
rd /s /q llama3.2\build 2> nul
rd /s /q llama3.2\dist 2> nul
rd /s /q llama3.2\lib 2> nul
goto :eof

:build
echo [^+] Building the GhidraChatGPT Plugin >&2

set GHIDRA_INSTALL_DIR=%GHIDRA_PATH%
pushd ghidrachatgpt > nul
gradle

for %%f in (dist\*.zip) do (
    set APPNAME=%%~nxf
    copy "dist\*.zip" "%GHIDRA_PATH%\Extensions\Ghidra"
    echo [^+] Built %APPNAME% and copied it to %GHIDRA_PATH%\Extensions\Ghidra\%APPNAME%
)
popd > nul

echo [^+] Building the llama3.2 Plugin >&2
pushd llama3.2 > nul
gradle

for %%f in (dist\*.zip) do (
    set APPNAME=%%~nxf
    copy "dist\*.zip" "%GHIDRA_PATH%\Extensions\Ghidra"
    echo [^+] Built %APPNAME% and copied it to %GHIDRA_PATH%\Extensions\Ghidra\%APPNAME%
)
popd > nul
goto :eof

:usage
echo Usage: %0 [OPTION...] [CMD] >&2
echo   -p PATH        PATH to local Ghidra installation >&2
echo   -c             Clean >&2
echo   -d             Build with Docker >&2
echo   -f             Force rebuild of the Docker image >&2
echo   -h             Show this help >&2
goto :eof

:getopts
set "opt=%~1"
if "%opt%"=="" goto :eof
shift
if "%opt%"=="-p" (
    set GHIDRA_PATH=%~1
    shift
) else if "%opt%"=="-d" (
    set DOCKER_BUILD=1
) else if "%opt%"=="-f" (
    set FORCE_BUILD=1
) else if "%opt%"=="-c" (
    call :clean
    exit /b 0
) else if "%opt%"=="-h" (
    call :usage
    exit /b 0
) else (
    echo Unknown option: %opt% >&2
    call :usage
    exit /b 1
)
goto :getopts

:getopts
if "%GHIDRA_PATH%"=="" (
    echo GHIDRA_PATH is not configured or is not a directory
    exit /b 1
)

if %DOCKER_BUILD% neq 0 (
    call :docker_build
) else (
    call :build
)

exit /b 0
