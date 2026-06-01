@echo off
setlocal enabledelayedexpansion

goto :main

REM ------------------------------------------------------------
REM clean_dir
REM   Cleans (deletes) a directory if it exists.
REM   Args: %1 - path to directory
REM   Returns: exit code 0 always
REM ------------------------------------------------------------
:clean_dir
    set "DIR_PATH=%~1"
    if exist "%DIR_PATH%" (
        attrib -s -h -r "%DIR_PATH%" /s /d >nul 2>&1
        rmdir /s /q "%DIR_PATH%" >nul 2>&1
    )
    exit /b 0

REM ------------------------------------------------------------
REM log_message
REM   Echoes the given message to stdout.
REM   Args: %* - message text (can contain spaces)
REM   Returns: exit code 0
REM ------------------------------------------------------------
:log_message
    echo %*
    exit /b 0

REM ------------------------------------------------------------
REM collect_source_files
REM   Recursively collects .cpp, .cc, .h, .hpp files from given directories.
REM   Args: %1 - space-separated list of directories
REM   Returns: 
REM     - sets variable FILES (space‑separated quoted absolute paths)
REM     - exit code 0 if at least one file found, else 1
REM ------------------------------------------------------------
:collect_source_files
    set "COLLECT_DIRS=%~1"
    set "FILES="
    for %%D in (%COLLECT_DIRS%) do (
        if exist "%%D" (
            pushd "%%D" 2>nul
            if not errorlevel 1 (
                for /R . %%F in (*.cpp *.cc *.h *.hpp) do set "FILES=!FILES! "%%~fF""
                popd
            ) else (
                call :log_message "Warning: cannot pushd into %%D"
            )
        ) else (
            call :log_message "Warning: directory does not exist: %%D"
        )
    )
    if "!FILES!"=="" exit /b 1
    exit /b 0

REM ------------------------------------------------------------
REM check_and_apply_clang_format
REM   Checks formatting with clang-format; applies it if any errors found.
REM   Uses global variables: SRC_DIR, INCLUDE_DIR, TESTS_DIR, CLANG_FORMAT
REM   Returns: exit code 0 if format check succeeded (or after applying),
REM            exit code 1 if collecting files failed.
REM ------------------------------------------------------------
:check_and_apply_clang_format
    set "FORMAT_DIRS=%SRC_DIR% %INCLUDE_DIR% %TESTS_DIR%"
    set "FORMAT_ERRORS=0"
    
    call :collect_source_files "%FORMAT_DIRS%"
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )

    call :log_message Running clang-format check...
    for %%F in (!FILES!) do (
        %CLANG_FORMAT% --dry-run --Werror "%%~F" >nul 2>&1
        if !ERRORLEVEL! neq 0 (
            set "FORMAT_ERRORS=1"
            call :log_message Formatting errors found in "%%~F". Formatting will be applied.
        )
    )
    
    if !FORMAT_ERRORS! equ 1 (
        call :log_message Applying clang-format...
        for %%F in (!FILES!) do (
            %CLANG_FORMAT% -i "%%~F"
        )
        call :log_message clang-format applied. Please check the changes.
    ) else (
        call :log_message All files are formatted correctly.
    )
    exit /b 0

REM ------------------------------------------------------------
REM update_compile_commands
REM   Generates compile_commands.json using CMake with Ninja generator.
REM   Args: %1 - build directory, %2 - BUILD_TESTS (ON/OFF)
REM   Uses global: ROOT_DIR, LLVM_BIN
REM   Returns: exit code 0 on success, non‑zero on failure.
REM ------------------------------------------------------------
:update_compile_commands
    set "BUILD_DIR=%~1"
    set "BUILD_TESTS=%~2"
    
    call :check_and_apply_clang_format
    if %ERRORLEVEL% neq 0 (
        call :log_message "Failed to check and apply clang format"
        exit /b %ERRORLEVEL%
    )
    
    if not exist "%BUILD_DIR%" (
        mkdir "%BUILD_DIR%"
    )
    
    cmake -S "%ROOT_DIR%" -B "%BUILD_DIR%" ^
        -G "Ninja" ^
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ^
        -DCMAKE_CXX_COMPILER=%LLVM_BIN%\clang++.exe ^
        -DCMAKE_C_COMPILER=%LLVM_BIN%\clang.exe ^
        -DCMAKE_BUILD_TYPE=Debug ^
        -DBUILD_TESTS=%BUILD_TESTS%
        
    if %ERRORLEVEL% neq 0 (
        call :log_message "Failed to generate compile_commands.json"
        exit /b %ERRORLEVEL%
    )
    if not exist "%BUILD_DIR%\compile_commands.json" (
        call :log_message "compile_commands.json not found in %BUILD_DIR%"
        exit /b 1
    )
    call :log_message "compile_commands.json updated at %BUILD_DIR%\compile_commands.json"
    exit /b 0

REM ------------------------------------------------------------
REM run_clang_tidy
REM   Runs clang-tidy on source files from given directories.
REM   Args: %1 - path to .clang-tidy config file
REM         %2 - build directory (for compile_commands.json)
REM         %3 - BUILD_TESTS (ON/OFF)
REM         %4 - space-separated directories to check
REM   Uses global: CLANG_TIDY
REM   Returns: exit code 0 on success, non‑zero on any error.
REM ------------------------------------------------------------
:run_clang_tidy
    set "CFG=%~1"
    set "BUILD_DIR=%~2"
    set "BUILD_TESTS=%~3"
    set "CHECK_DIRS=%~4"

    call :update_compile_commands "%BUILD_DIR%" "%BUILD_TESTS%"
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )

    call :collect_source_files "%CHECK_DIRS%"
    if %ERRORLEVEL% neq 0 (
        exit /b %ERRORLEVEL%
    )

    for %%F in (!FILES!) do (
        call :log_message [clang-tidy] %%~F
        %CLANG_TIDY% "%%~F" --config-file="%CFG%" -p "%BUILD_DIR%" --warnings-as-errors=*
        if !ERRORLEVEL! neq 0 (
            exit /b !ERRORLEVEL!
        )
    )
    call :log_message "clang-tidy finished successfully."
    exit /b 0

REM ------------------------------------------------------------
REM get_num_jobs
REM   Returns the number of CPU cores (reads NUMBER_OF_PROCESSORS).
REM   Returns: exit code 0, and the number is echoed by log_message.
REM ------------------------------------------------------------
:get_num_jobs
    set "NUM_JOBS=1"
    if defined NUMBER_OF_PROCESSORS set "NUM_JOBS=%NUMBER_OF_PROCESSORS%"
    call :log_message %NUM_JOBS%
    exit /b 0

REM ------------------------------------------------------------
REM compile_with_msvc
REM   Compiles a single file using MSVC cl.exe.
REM   Args: arguments to pass to cl.exe (e.g. /c, /I, etc.)
REM   Uses global: MSVC_CL
REM   Returns: exit code 0 on success, non-zero on failure
REM ------------------------------------------------------------
:compile_with_msvc
    if "%~1"=="" (
        call :log_message "No arguments passed to cl.exe"
        exit /b 1
    )
    "%MSVC_CL%" %*
    if %ERRORLEVEL% neq 0 (
        call :log_message "MSVC compilation failed."
        exit /b %ERRORLEVEL%
    )
    call :log_message "MSVC compilation finished successfully."
    exit /b 0

REM ------------------------------------------------------------
REM detect_vs_major
REM   Detects the installed Visual Studio version using vswhere.
REM   Requires MSVC component. Exits with error if version is not 17 (VS2022).
REM   Returns: exit code 0 if VS2022 is found, and outputs major version.
REM ------------------------------------------------------------
:detect_vs_major
    set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
    for /f "usebackq tokens=*" %%V in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion`) do set "VS_VER=%%V"
    for /f "tokens=1 delims=." %%a in ("%VS_VER%") do set "MAJOR_VER=%%a"
    if "%MAJOR_VER%"=="" (
        call :log_message "Failed to detect Visual Studio version"
        exit /b 1
    )
    if not "%MAJOR_VER%"=="17" (
        call :log_message "Unsupported Visual Studio version: %MAJOR_VER%, supported only 22 version"
        exit /b 1
    )
    call :log_message %MAJOR_VER%
    exit /b 0

REM ------------------------------------------------------------
REM Entry point (dispatcher)
REM   Calls the function specified by the first argument, passing remaining args.
REM   If no arguments, does nothing.
REM ------------------------------------------------------------
:main
    if "%~1"=="" exit /b 0
    call :%*
    exit /b %ERRORLEVEL%