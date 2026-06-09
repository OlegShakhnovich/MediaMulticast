@echo off
setlocal enabledelayedexpansion

REM Include common and config files
set "COMMON=%~dp0..\common\common.bat"
call "%~dp0..\common\config.bat"
if %ERRORLEVEL% neq 0 (
    exit /b %ERRORLEVEL%
)
call "%COMMON%"

REM Function to build the project using Ninja
:build_with_ninja
    call "%COMMON%" :log_message "Starting update_compile_commands..."
    set "BUILD_DIR=%TIDY_DIR%"
    call "%COMMON%" :update_compile_commands "%BUILD_DIR%" "OFF"
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )

    REM Get the number of available CPU cores
    for /f "delims=" %%J in ('call "%COMMON%" :get_num_jobs') do set "NUM_JOBS=%%J"

    REM Build the project
    echo Building with %NUM_JOBS% jobs...
    cmake --build "%BUILD_DIR%" -- -j%NUM_JOBS%
    if %ERRORLEVEL% neq 0 (
        call "%COMMON%" :log_message "Build failed."
        exit /b %ERRORLEVEL%
    )
    
    cmake --install "%BUILD_DIR%" --prefix "%INSTALL_DIR%\ninja"
    if %ERRORLEVEL% neq 0 (
        call "%COMMON%" :log_message "Installation failed."
        exit /b %ERRORLEVEL%
    )
    
    call "%COMMON%" :log_message "Build and installation completed successfully."
    exit /b 0

REM Call the function to build the project
call :build_with_ninja
endlocal
