@echo off
setlocal

rem === Define relative paths ===
set "BUILD_REL=..\build\build_vs"
set "INSTALL_REL=..\install\vs"
set "PROJECT_ROOT_REL=.."

rem === Resolve absolute paths ===
for %%I in ("%~dp0%BUILD_REL%") do set "BUILD_DIR=%%~fI"
for %%I in ("%~dp0%INSTALL_REL%") do set "INSTALL_DIR=%%~fI"
for %%I in ("%~dp0%PROJECT_ROOT_REL%") do set "PROJECT_ROOT=%%~fI"
set "BUILD_DIR=%BUILD_DIR:\=/%"
set "INSTALL_DIR=%INSTALL_DIR:\=/%"
set "PROJECT_ROOT=%PROJECT_ROOT:\=/%"

rem === Remove previous build and install directories ===
echo Deleting build dir: "%BUILD_DIR%"
if exist "%BUILD_DIR%" (
    attrib -s -h -r "%BUILD_DIR%" /s /d >nul 2>&1
    rmdir /s /q "%BUILD_DIR%" >nul 2>&1
)

echo Deleting install dir: "%INSTALL_DIR%"
if exist "%INSTALL_DIR%" (
    attrib -s -h -r "%INSTALL_DIR%" /s /d >nul 2>&1
    rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
)

rem === Detect latest installed Visual Studio using vswhere ===
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%V in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion`) do set "VS_VER=%%V"

rem === Choose generator based on VS version ===
set "GENERATOR="
for /f "tokens=1 delims=." %%a in ("%VS_VER%") do set "MAJOR_VER=%%a"
if "%MAJOR_VER%"=="16" set "GENERATOR=Visual Studio 16 2019"
if "%MAJOR_VER%"=="17" set "GENERATOR=Visual Studio 17 2022"

if "%GENERATOR%"=="" (
    echo No supported Visual Studio version found.
    pause
    exit /b 1
)

echo Using generator: %GENERATOR%

rem === Build and install ===
cmake -S "%PROJECT_ROOT%" -B "%BUILD_DIR%" -G "%GENERATOR%" -A x64
if errorlevel 1 goto err

cmake --build "%BUILD_DIR%" --config Release
if errorlevel 1 goto err

cmake --install "%BUILD_DIR%" --prefix "%INSTALL_DIR%"
if errorlevel 1 goto err

echo === Done ===
pause
exit /b 0

:err
echo === Build failed ===
pause
exit /b 1
