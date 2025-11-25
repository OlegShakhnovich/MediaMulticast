@echo off
setlocal

rem === Define relative paths ===
set "BUILD_REL=..\build\build_vs"
set "INSTALL_REL=..\install\vs"
set "FORMAT_BUILD=..\build\build_format"
set "TIDY_BUILD=..\build\build_tidy"
set "PROJECT_ROOT_REL=.."

rem === Resolve paths ===
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

rem === Cleanup ===
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

rem === clang-tidy ===
echo Running clang-tidy...
cmake -S "." -B "%TIDY_DIR%" -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

for /R "src" %%F in (*.cpp *.cc *.h *.hpp) do clang-tidy -p "%TIDY_DIR%" --warnings-as-errors=* "%%F"
for /R "include" %%F in (*.h *.hpp) do clang-tidy -p "%TIDY_DIR%" --warnings-as-errors=* "%%F"

rem === VS detection ===
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%V in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion`) do set "VS_VER=%%V"

set "GENERATOR="
for /f "tokens=1 delims=." %%a in ("%VS_VER%") do set "MAJOR_VER=%%a"
if "%MAJOR_VER%"=="17" set "GENERATOR=Visual Studio 17 2022"
if "%MAJOR_VER%"=="16" set "GENERATOR=Visual Studio 16 2019"

echo Using generator: %GENERATOR%

rem === build ===
cmake -S "." -B "%BUILD_DIR%" -G "%GENERATOR%" -A x64 -DCMAKE_BUILD_TYPE=Release
cmake --build "%BUILD_DIR%" --config Release --parallel
cmake --install "%BUILD_DIR%" --prefix "%INSTALL_DIR%" --config Release

echo === Done ===
pause
exit /b 0
