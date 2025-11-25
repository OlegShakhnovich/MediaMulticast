@echo off
setlocal enabledelayedexpansion

rem --- Paths ---
set TIDY_EXE="C:\Program Files\LLVM\bin\clang-tidy.exe"
set CFG="%~dp0\..\.clang-tidy"
set ROOT="%~dp0..\..%"
set SRC_DIR=%ROOT%\src
set INCLUDE_DIR=%ROOT%\include

rem --- Collect files from src and include ---
set FILES=
for /R "%SRC_DIR%" %%F in (*.cpp *.cc *.h *.hpp) do (
    set FILES=!FILES! "%%F"
)
for /R "%INCLUDE_DIR%" %%F in (*.cpp *.cc *.h *.hpp) do (
    set FILES=!FILES! "%%F"
)

if "!FILES!"=="" (
    echo No source or header files found in src/include
    pause
    exit /b 0
)

rem --- Run clang-tidy on each file ---
for %%F in (!FILES!) do (
    echo [clang-tidy] %%F
    %TIDY_EXE% "%%F" --config-file=%CFG% --warnings-as-errors=*
    if %ERRORLEVEL% neq 0 (
        pause
        exit /b %ERRORLEVEL%
    )
)

rem --- Compile with actual MSVC ---
"C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe" %*
pause
exit /b %ERRORLEVEL%
