@echo off
setlocal enabledelayedexpansion

REM Include common and config files
set "COMMON=%~dp0..\common\common.bat"
call "%~dp0..\common\config.bat"
if %ERRORLEVEL% neq 0 (
    exit /b %ERRORLEVEL%
)
call "%COMMON%"

REM Function to run clang-tidy and then compile with MSVC
:msvc_tidy_wrapper
    set "CHECK_DIRS=%SRC_DIR% %INCLUDE_DIR%"
    call "%COMMON%" :run_clang_tidy "%ROOT_DIR%\.clang-tidy" "%TIDY_DIR%" "OFF" "%CHECK_DIRS%"
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )
    
    call "%COMMON%" :compile_with_msvc %*
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )
    exit /b 0

REM Call the function to run clang-tidy and compile with MSVC
call :msvc_tidy_wrapper
endlocal
