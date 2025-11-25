@echo off
setlocal enabledelayedexpansion

rem === Detect script directory and project root ===
for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
set "TIDY_DIR=%PROJECT_ROOT%\build\build_tidy"

rem === Normalize slashes ===
set "PROJECT_ROOT=%PROJECT_ROOT:\=/%"
set "TIDY_DIR=%TIDY_DIR:\=/%"

echo PROJECT_ROOT=%PROJECT_ROOT%
echo TIDY_DIR=%TIDY_DIR%

rem === Prepare LLVM ===
set "LLVM_BIN=C:/Program Files/LLVM/bin"
set PATH=%LLVM_BIN%;%PATH%

rem === Cleanup old ===
if exist "%TIDY_DIR%" (
    attrib -s -h -r "%TIDY_DIR%" /s /d >nul 2>&1
    rmdir /s /q "%TIDY_DIR%" >nul 2>&1
)

rem === Generate compile_commands.json ===
cmake -S "%PROJECT_ROOT%" -B "%TIDY_DIR%" ^
    -G "Ninja" ^
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ^
    -DCMAKE_CXX_COMPILER=clang++.exe ^
    -DCMAKE_C_COMPILER=clang.exe ^
    -DCMAKE_CXX_STANDARD=20 ^
    -DCMAKE_BUILD_TYPE=Debug

echo === compile_commands.json generated at %TIDY_DIR%/compile_commands.json ===
pause
endlocal
