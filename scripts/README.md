# UDP Streaming Library - Build & Static Analysis

## Overview

This project provides a C++20 UDP streaming library and executable.  
The repository supports **cross-platform builds** (Windows, Linux, macOS) using **CMake + Ninja**, Clang tools for formatting and static analysis, and GoogleTest for unit tests.

---

## Clang Tools Integration

- `clang-format` ensures consistent code style.
- `clang-tidy` performs static analysis.
- `compile_commands.json` generated in `build/build_tidy` ensures **identical Clang diagnostics locally and in CI**.
- MSVC Variant B in VS22 automatically reads `compile_commands.json` from the build directory to show the same tidy warnings.

> Note: `CMAKE_EXPORT_COMPILE_COMMANDS=ON` is required for Clang tools to work properly.  

---

## Scripts

All scripts assume they are run **from `scripts/` folder**.

### Linux / macOS

```bash
# Build, format, tidy, and install in one command
./build_all.sh
```

- Checks formatting with `clang-format`.
- Runs `clang-tidy` over all `.cpp`, `.cc`, `.h`, `.hpp` files.
- Builds the library and executable using Ninja.
- Installs outputs to `install/ninja`.

### Windows (Ninja + Clang)

```bat
build_ninja.bat
```

- Checks formatting and runs `clang-tidy` using `build/build_tidy`.
- Builds library and executable with Ninja.
- Installs to `install/ninja`.

### Windows (MSVC)

```bat
build_vs.bat
```

- Builds library and executable using Visual Studio 2022.
- Install path: `install/vs`.
- Uses Ninja generator for VS22 Variant B to read `compile_commands.json` automatically.

### Generate compile_commands.json manually

- Linux / macOS:

```bash
./gen_compile_commands.sh
```

- Windows:

```bat
gen_compile_commands.bat
```

### Run clang-tidy manually

- Linux / macOS:

```bash
./run_tidy.sh
```

- Windows:

```powershell
.\run_tidy.ps1
```

> This ensures Clang diagnostics exactly match CI output.

---

## Build Directories

| Script             | Build dir                  | Install dir         | Notes                                      |
|-------------------|---------------------------|-------------------|--------------------------------------------|
| build_all.sh       | build/build_ninja         | install/ninja      | Also creates build/build_format & build_tidy |
| build_ninja.bat    | build/build_ninja         | install/ninja      | Windows Ninja + Clang                       |
| build_vs.bat       | build/build_vs            | install/vs         | MSVC Variant B                              |
| gen_compile_commands | build/build_tidy         | -                  | Compile commands for Clang analysis        |

---

## CMake Presets

- **MSVC Debug / Release**: builds with cl.exe, generate `compile_commands.json`.
- **Clang-Tidy Debug / Release**: builds with clang++ + Ninja, ensures exact CI diagnostics.
- Use:

```bash
cmake --preset clang-tidy-debug
cmake --build --preset build-tidy-debug
```

---

## VS2022 Integration (Variant B)

1. Enable **Clang-Tidy** in CMake Settings.
2. Variant B automatically picks up `compile_commands.json` from `binaryDir`.
3. No need to modify `.vsconfig` or add unsupported fields in presets.

---

## Notes

- All source files are in `src/` and `include/`.
- Tests are in `tests/` and use GoogleTest.
- Local tidy for tests is separate from root tidy to avoid false positives.
- ccache is used for Linux/macOS to accelerate rebuilds.