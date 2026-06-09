@echo off
setlocal enabledelayedexpansion

REM Include common and config files
set "COMMON=%~dp0..\common\common.bat"
call "%~dp0..\common\config.bat"
if %ERRORLEVEL% neq 0 (
    exit /b %ERRORLEVEL%
)
call "%COMMON%"

REM Function to build the project using Visual Studio
:build_with_vs
    set "BUILD_DIR=%BUILD_VS_DIR%"
    set "BUILD_TESTS=OFF"
    
    REM Function to check and apply clang-format
    call "%COMMON%" :check_and_apply_clang_format
    if %ERRORLEVEL% neq 0 (
        call "%COMMON%" :log_message "Failed to check and apply clang format"
        exit /b %ERRORLEVEL%
    )
    
    REM Determine the Visual Studio generator    
    for /f "delims=" %%V in ('call "%COMMON%" :detect_vs_major') do set "VS_MAJOR=%%V"
    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

    if "%VS_MAJOR%"=="17" (
        set "GENERATOR=Visual Studio 17 2022"
    ) else (
        call "%COMMON%" :log_message "Unsupported Visual Studio version: %VS_MAJOR%, expected 17"
        exit /b 1
    )
    call "%COMMON%" :log_message "Using generator: %GENERATOR%"
    
    REM Build the project
    echo Building with %GENERATOR%...
    cmake -S "%ROOT_DIR%" -B "%BUILD_DIR%" -G "%GENERATOR%" -A x64 -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTS=%BUILD_TESTS%
    if %ERRORLEVEL% neq 0 (
        call "%COMMON%" :log_message "CMake configuration failed."
        exit /b %ERRORLEVEL%
    )
    
    cmake --build "%BUILD_DIR%" --config Debug --parallel
    if %ERRORLEVEL% neq 0 (
        call "%COMMON%" :log_message "Build failed."
        exit /b %ERRORLEVEL%
    )
    
    cmake --install "%BUILD_DIR%" --prefix "%INSTALL_DIR%\vs" --config Debug
    if %ERRORLEVEL% neq 0 (
        call "%COMMON%" :log_message "Installation failed."
        exit /b %ERRORLEVEL%
    )
    
    call "%COMMON%" :log_message "Build and installation completed successfully."
    exit /b 0

REM Call the function to build the project
call :build_with_vs
endlocal
