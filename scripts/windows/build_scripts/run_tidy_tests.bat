@echo off
setlocal enabledelayedexpansion

REM Include common and config files
set "COMMON=%~dp0..\common\common.bat"
call "%~dp0..\common\config.bat"
if %ERRORLEVEL% neq 0 (
    exit /b %ERRORLEVEL%
)
call "%COMMON%"

REM Function to run clang-tidy on tests
:run_tidy_tests
    set "CHECK_DIRS=%TESTS_DIR%"
    call "%COMMON%" :run_clang_tidy "%TESTS_DIR%\.clang-tidy" "%TIDY_TESTS_DIR%" "ON" "%CHECK_DIRS%"
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )

    exit /b 0

REM Call the function to run clang-tidy
call :run_tidy_tests
endlocal
