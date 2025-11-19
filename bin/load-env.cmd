@echo off
if [%1]==[] (
    echo Usage: %~n0 ^<path-to-env-file^>
    exit /b 1
)

set "ENV_FILE_PATH=%~f1"

for /f "usebackq delims=" %%i in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0load-env.ps1" -EnvFilePath "%ENV_FILE_PATH%" -ForCmd`) do (
    call "%%i"
    del "%%i"
)

set "ENV_FILE_PATH="