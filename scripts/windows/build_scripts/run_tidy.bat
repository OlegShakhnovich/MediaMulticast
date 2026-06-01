@echo off
setlocal enabledelayedexpansion

REM Include common and config files
set "COMMON=%~dp0..\common\common.bat"
call "%~dp0..\common\config.bat"
if %ERRORLEVEL% neq 0 (
    exit /b %ERRORLEVEL%
)
call "%COMMON%"

REM Function to run clang-tidy on src and include
:run_tidy
    set "CHECK_DIRS=%SRC_DIR% %INCLUDE_DIR%"
    call "%COMMON%" :run_clang_tidy "%ROOT_DIR%\.clang-tidy" "%TIDY_DIR%" "OFF" "%CHECK_DIRS%"
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )

    exit /b 0

REM Call the function to run clang-tidy
call :run_tidy
endlocal
