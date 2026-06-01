Here is the documentation text again, ready for you to copy and save as a `.md` file.

---

# Scripts Documentation

This document describes the build and code quality automation scripts for the project. The scripts are organized into Unix (bash) and Windows (batch) versions, providing cross‑platform support for running **clang-format**, **clang-tidy**, and building the project with **Ninja** or **Visual Studio**.

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Common Scripts](#common-scripts)
  - [Windows (`common.bat`, `config.bat`)](#windows-commonbat-configbat)
  - [Unix (`common.sh`, `config.sh`)](#unix-commonsh-configsh)
- [Configuration](#configuration)
- [Build Scripts](#build-scripts)
  - [Windows](#windows-build-scripts)
  - [Unix](#unix-build-scripts)
- [Tidy Scripts (clang‑tidy)](#tidy-scripts-clang-tidy)
- [MSVC Wrappers (Windows only)](#msvc-wrappers-windows-only)
- [Usage Examples](#usage-examples)
- [Requirements](#requirements)
- [Notes](#notes)

---

## Overview

The scripts automate the following tasks:

- **Code formatting** with `clang-format` (check + apply)
- **Static analysis** with `clang-tidy`
- **Generation of `compile_commands.json`** using CMake + Ninja
- **Building** the project with either Ninja or Visual Studio 2022
- **Integration with Visual Studio** – running `clang-tidy` and `clang-format` before an MSVC build

All scripts share common functions (logging, file collection, directory cleanup) defined in `common.bat` / `common.sh`. Configuration (paths, tool versions, directories) is kept in `config.bat` / `config.sh`.

---

## Directory Structure

```
project_root/
├── include/                      # public headers
├── src/                          # source files
├── tests/                        # test sources
├── scripts/
│   ├── unix/
│   │   ├── common/
│   │   │   ├── common.sh
│   │   │   └── config.sh
│   │   └── build_scripts/
│   │       ├── build_ninja.sh
│   │       ├── run_tidy.sh
│   │       └── run_tidy_tests.sh
│   └── windows/
│       ├── common/
│       │   ├── common.bat
│       │   └── config.bat
│       └── build_scripts/
│           ├── build_ninja.bat
│           ├── build_vs.bat
│           ├── run_tidy.bat
│           ├── run_tidy_tests.bat
│           ├── msvc_tidy_wrapper.bat
│           └── msvc_tidy_wrapper_tests.bat
```

All paths inside the scripts are derived relative to the script location (e.g., `../../..` points to `project_root`).

---

## Common Scripts

### Windows (`common.bat`, `config.bat`)

**`common.bat`**  
Provides reusable subroutines (called with `call :function_name`).  
Main functions:

| Function | Description |
|----------|-------------|
| `:clean_dir` | Removes a directory (if exists) after stripping system/hidden/read‑only attributes. |
| `:log_message` | Prints a message to stdout. |
| `:collect_source_files` | Recursively collects `.cpp`, `.cc`, `.h`, `.hpp` from given directories. Returns a space‑separated list in variable `FILES`. |
| `:check_and_apply_clang_format` | Runs `clang-format --dry-run` on all collected source files; if any errors, applies formatting in‑place. |
| `:update_compile_commands` | Configures CMake with Ninja generator, exports `compile_commands.json`. Calls `:check_and_apply_clang_format` first. |
| `:run_clang_tidy` | Generates `compile_commands.json`, collects sources, runs `clang-tidy` with `--warnings-as-errors=*`. |
| `:get_num_jobs` | Returns the number of CPU cores (reads `NUMBER_OF_PROCESSORS`). |
| `:detect_vs_major` | Uses `vswhere.exe` to detect Visual Studio version; requires VS2022 (major version 17). |

**`config.bat`**  
Sets environment variables:

- `LLVM_BIN` – path to LLVM binaries (e.g., `C:/PROGRA~1/LLVM/bin`)
- `CLANG_TIDY`, `CLANG_FORMAT` – full paths to the tools
- `ROOT_DIR` – absolute path to `project_root` (derived from script location)
- `TIDY_DIR`, `TIDY_TESTS_DIR`, `INSTALL_DIR`, `INCLUDE_DIR`, `SRC_DIR`, `TESTS_DIR`, `BUILD_VS_DIR`

Also checks the version of `clang-format` and `clang-tidy` against **21.1.6** (exact match required).

### Unix (`common.sh`, `config.sh`)

**`common.sh`**  
Bash functions (sourced, not executed).  
Main functions:

| Function | Description |
|----------|-------------|
| `log_message` / `error_log` | Print to stdout / stderr. |
| `clean_dir` | Remove directory with `rm -rf`. |
| `collect_source_files` | Uses `find` to collect source files, outputs one absolute path per line. |
| `check_and_apply_clang_format` | Same logic as Windows version. |
| `update_compile_commands` | Runs CMake with Ninja. |
| `run_clang_tidy` | Runs `clang-tidy` with `--warnings-as-errors=*`. |
| `get_num_jobs` | Detects CPU cores using `nproc`, `/proc/cpuinfo`, or `sysctl`. |

**`config.sh`**  
Defines:

- `REQUIRED_LLVM_VERSION="21.1.6"`
- `LLVM_BIN` – auto‑detects common installation paths (`/usr/local/llvm/bin`, `/usr/local/opt/llvm/bin`, or `/usr/bin`)
- `CLANG_TIDY`, `CLANG_FORMAT`
- `ROOT_DIR` – absolute path to `project_root`
- Build directories: `TIDY_DIR`, `TIDY_TESTS_DIR`, `INSTALL_DIR`, `INCLUDE_DIR`, `SRC_DIR`, `TESTS_DIR`

Also validates tool versions (exact match required) and exits on mismatch.

---

## Configuration

Both platforms require **LLVM 21.1.6** (`clang-format`, `clang-tidy`).  
Paths can be overridden inside `config.bat` or `config.sh`.  

On Windows, the scripts assume:

- Visual Studio 2022 is installed (detected via `vswhere`).
- MSVC compiler is available (used by wrapper scripts).

On Unix, the scripts assume:

- `cmake`, `ninja`, and a working C++ compiler (e.g., `clang++`) are in `PATH` (except the LLVM tools which are taken from `LLVM_BIN`).

---

## Build Scripts

All build scripts source the common scripts, set up required environment variables, and invoke the build.

### Windows Build Scripts

**`build_ninja.bat`**  
- Calls `:update_compile_commands` to generate `compile_commands.json` (with `BUILD_TESTS=OFF`).  
- Builds using `cmake --build` with Ninja, parallel jobs = number of CPU cores.  
- Installs to `%INSTALL_DIR%\ninja`.  

**`build_vs.bat`**  
- Runs `:check_and_apply_clang_format` first.  
- Detects VS version (requires VS2022).  
- Configures CMake with generator `Visual Studio 17 2022` (x64).  
- Builds with `cmake --build --parallel`.  
- Installs to `%INSTALL_DIR%\vs`.  

### Unix Build Scripts

**`build_ninja.sh`**  
- Calls `update_compile_commands` (BUILD_TESTS=OFF).  
- Builds with Ninja, parallel jobs.  
- Installs to `$INSTALL_DIR/ninja`.  

*(Note: No Visual Studio build script exists for Unix – only Ninja.)*

---

## Tidy Scripts (clang‑tidy)

These scripts run `clang-tidy` on the source code, using the appropriate `.clang-tidy` configuration file.

| Script | Target directories | clang-tidy config file | BUILD_TESTS |
|--------|--------------------|------------------------|--------------|
| `run_tidy.bat` / `run_tidy.sh` | `src/`, `include/` | `%ROOT_DIR%/.clang-tidy` | OFF |
| `run_tidy_tests.bat` / `run_tidy_tests.sh` | `tests/` | `%TESTS_DIR%/.clang-tidy` | ON |

Each script:

1. Calls `:run_clang_tidy` (Windows) or `run_clang_tidy` (Unix).
2. That function internally runs `update_compile_commands` (generates `compile_commands.json`).
3. Collects source files and invokes `clang-tidy` on each, treating all warnings as errors (`--warnings-as-errors=*`).
4. Exits with non‑zero code if any violation is found.

---

## MSVC Wrappers (Windows only)

The wrapper scripts are designed to be used **inside a Visual Studio 2022 Developer Command Prompt**. They combine static analysis and formatting with an actual MSVC build.

**`msvc_tidy_wrapper.bat`**  
- Runs `:run_clang_tidy` for `src/` and `include/` (using `%ROOT_DIR%/.clang-tidy`, BUILD_TESTS=OFF).  
- Then calls `:compile_with_msvc` (a function that must be defined elsewhere – in the provided code it is referenced but not implemented; the user should implement it or the wrapper will fail).  

**`msvc_tidy_wrapper_tests.bat`**  
- Same but for the `tests/` directory, using `%TESTS_DIR%/.clang-tidy` and BUILD_TESTS=ON.  

> **Note:** The `:compile_with_msvc` subroutine is **not** provided in the snippets. It is expected to invoke the MSVC compiler (`cl.exe`) with appropriate flags to build the project. The wrapper scripts are examples of how to integrate `clang-tidy` into an MSVC‑based workflow.

---

## Usage Examples

### Windows

Open a **VS2022 Developer Command Prompt**, then:

```cmd
:: Run clang-tidy on src/ and include/
cd C:\path\to\project_root\scripts\windows\build_scripts
run_tidy.bat

:: Run clang-tidy on tests/
run_tidy_tests.bat

:: Build with Ninja (requires Ninja in PATH)
build_ninja.bat

:: Build with Visual Studio
build_vs.bat

:: Run clang-tidy then MSVC build (needs :compile_with_msvc implemented)
msvc_tidy_wrapper.bat
```

### Unix (Linux / macOS)

```bash
cd /path/to/project_root/scripts/unix/build_scripts

# Run clang-tidy on src/ and include/
./run_tidy.sh

# Run clang-tidy on tests/
./run_tidy_tests.sh

# Build with Ninja
./build_ninja.sh
```

All scripts exit with a non‑zero code on failure.

---

## Requirements

### Windows
- **Visual Studio 2022** (Community, Professional, or Enterprise) with C++ toolchain.
- **LLVM 21.1.6** – installed and the `bin` folder configured in `config.bat`.
- **CMake** (3.15+) – in `PATH`.
- **Ninja** – in `PATH` (for `build_ninja.bat`).
- **`vswhere.exe`** – usually present with Visual Studio.

### Unix
- **LLVM 21.1.6** – `clang-format` and `clang-tidy` must be reachable (paths detected automatically).
- **CMake** (3.15+)
- **Ninja**
- **Bash** 4+ and standard Unix tools (`find`, `grep`, etc.)

---

## Notes

- The Windows scripts rely on **delayed expansion** (`enabledelayedexpansion`) and use `call :function` to simulate subroutines.
- The `:compile_with_msvc` function is **placeholder** – you must implement it according to your project’s MSVC build steps (e.g., invoking `cl.exe` on specific source files, linking, etc.).
- The scripts assume the project layout: `include/`, `src/`, `tests/` are direct subdirectories of `project_root`.
- clang‑tidy runs with `--warnings-as-errors=*`, meaning any tidy warning will fail the script.
- Version check for LLVM tools is **strict** – only 21.1.6 is accepted. Modify the `REQUIRED_VERSION` / `REQUIRED_LLVM_VERSION` variables if a different version is needed.
- For Unix, the `CLANG_FORMAT` and `CLANG_TIDY` paths are determined automatically; override them in `config.sh` if necessary.
- The scripts do **not** modify system‑wide settings – all paths are relative or derived from the script’s location.

---

*Documentation generated for the current script implementation. For questions or improvements, please refer to the script comments or contact the maintainer.*