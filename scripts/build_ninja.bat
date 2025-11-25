@echo off
setlocal

rem === Define relative paths ===
set "BUILD_REL=..\build\build_ninja"
set "INSTALL_REL=..\install\ninja"
set "FORMAT_BUILD=..\build\build_format"
set "TIDY_BUILD=..\build\build_tidy"
set "PROJECT_ROOT_REL=.."

rem === Resolve absolute paths ===
for %%I in ("%~dp0%BUILD_REL%") do set "BUILD_DIR=%%~fI"
for %%I in ("%~dp0%INSTALL_REL%") do set "INSTALL_DIR=%%~fI"
for %%I in ("%~dp0%FORMAT_BUILD%") do set "FORMAT_DIR=%%~fI"
for %%I in ("%~dp0%TIDY_BUILD%") do set "TIDY_DIR=%%~fI"
for %%I in ("%~dp0%PROJECT_ROOT_REL%") do set "PROJECT_ROOT=%%~fI"

set "BUILD_DIR=%BUILD_DIR:\=/%"
set "INSTALL_DIR=%INSTALL_DIR:\=/%"
set "FORMAT_DIR=%FORMAT_DIR:\=/%"
set "TIDY_DIR=%TIDY_DIR:\=/%"
set "PROJECT_ROOT=%PROJECT_ROOT:\=/%"

rem === cleanup ===
for %%D in ("%BUILD_DIR%" "%INSTALL_DIR%" "%FORMAT_DIR%" "%TIDY_DIR%") do (
    if exist "%%~D" (
        attrib -s -h -r "%%~D" /s /d >nul 2>&1
        rmdir /s /q "%%~D" >nul 2>&1
    )
)

cd /d "%PROJECT_ROOT%"

rem === clang-format check ===
echo Running clang-format check...
cmake -S "." -B "%FORMAT_DIR%" -G "Ninja"

for /R "src" %%F in (*.cpp *.cc *.h *.hpp) do clang-format --dry-run --Werror "%%F"
for /R "include" %%F in (*.h *.hpp) do clang-format --dry-run --Werror "%%F"

rem === clang-tidy check ===
echo Running clang-tidy...
cmake -S "." -B "%TIDY_DIR%" -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

for /R "src" %%F in (*.cpp *.cc *.h *.hpp) do clang-tidy -p "%TIDY_DIR%" --warnings-as-errors=* "%%F"
for /R "include" %%F in (*.h *.hpp) do clang-tidy -p "%TIDY_DIR%" --warnings-as-errors=* "%%F"

rem === build ===
cmake -S "." -B "%BUILD_DIR%" -G "Ninja" -DCMAKE_BUILD_TYPE=Release
cmake --build "%BUILD_DIR%" --target udp_streaming_lib --parallel
cmake --build "%BUILD_DIR%" --target udp_streamer --parallel

cmake --install "%BUILD_DIR%" --prefix "%INSTALL_DIR%"

echo === Done ===
pause
exit /b 0
