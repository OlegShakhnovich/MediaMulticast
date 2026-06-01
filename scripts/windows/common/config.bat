@echo off

REM Configuration settings

set "LLVM_BIN=C:/PROGRA~1/LLVM/bin"
set "CLANG_TIDY=%LLVM_BIN%\clang-tidy.exe"
set "CLANG_FORMAT=%LLVM_BIN%\clang-format.exe"
set "MSVC_CL=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe"
set "ROOT_DIR=%~dp0..\..\..%"

REM Normalize the path to remove ".." and obtain an absolute path.
for /f "delims=" %%i in ("%ROOT_DIR%") do set "ROOT_DIR=%%~fi"

set "TIDY_DIR=%ROOT_DIR%\build\build_tidy"
set "TIDY_TESTS_DIR=%ROOT_DIR%\build\build_tidy_tests"
set "INSTALL_DIR=%ROOT_DIR%\install"
set "INCLUDE_DIR=%ROOT_DIR%\include"
set "SRC_DIR=%ROOT_DIR%\src"
set "TESTS_DIR=%ROOT_DIR%\tests"
set "BUILD_VS_DIR=%ROOT_DIR%\build\build_vs"

REM Check LLVM tools version
set "REQUIRED_VERSION=21.1.6"

call :check_llvm_tool_version "%CLANG_FORMAT%" "clang-format.exe"
if %errorlevel% neq 0 exit /b %errorlevel%
call :check_llvm_tool_version "%CLANG_TIDY%" "clang-tidy.exe"
if %errorlevel% neq 0 exit /b %errorlevel%

exit /b 0

:check_llvm_tool_version
set "tool_path=%~1"
set "tool_name=%~2"
if not exist "%tool_path%" (
    echo Error: %tool_name% not found at %tool_path% 1>&2
    exit /b 1
)

REM Capture the version line containing "version" and a three-part number.
REM We use a temporary file to avoid delayed expansion complications.
set "tempfile=%TEMP%\llvm_version.txt"
"%tool_path%" --version 2>nul | findstr /r "version [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" > "%tempfile%"
set /p version_line=<"%tempfile%"
del "%tempfile%"

if "%version_line%"=="" (
    echo Error: Could not retrieve version from %tool_name% 1>&2
    exit /b 1
)

REM Extract the version number (third token in the line, e.g. "clang-format version 21.1.6")
for /f "tokens=3 delims= " %%v in ("%version_line%") do set "actual_version=%%v"

if "%actual_version%"=="" (
    echo Error: Could not parse version from '%version_line%' 1>&2
    exit /b 1
)

if not "%actual_version%"=="%REQUIRED_VERSION%" (
    echo Error: Unsupported %tool_name% version: %actual_version% 1>&2
    echo        Required version: %REQUIRED_VERSION% 1>&2
    exit /b 1
)

echo Info: %tool_name% version %actual_version% (OK)
exit /b 0