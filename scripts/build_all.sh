#!/usr/bin/env bash
set -euo pipefail

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/.."

# Define build, install, format, and tidy directories
BUILD_DIR="${SRC_DIR}/build/build_ninja"
INSTALL_DIR="${SRC_DIR}/install/ninja"
FORMAT_DIR="${SRC_DIR}/build/build_format"
TIDY_DIR="${SRC_DIR}/build/build_tidy"

# Remove old directories
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}" "${FORMAT_DIR}" "${TIDY_DIR}"
mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}" "${FORMAT_DIR}" "${TIDY_DIR}"

# --- clang-format check ---
echo "Running clang-format check..."
cmake -S "${SRC_DIR}" -B "${FORMAT_DIR}" -G "Ninja"

# Find all source and header files recursively
find "${SRC_DIR}/src" -type f \( -name '*.cpp' -o -name '*.cc' -o -name '*.h' -o -name '*.hpp' \) -print0 | \
    xargs -0 -n1 clang-format --dry-run --Werror

find "${SRC_DIR}/include" -type f \( -name '*.h' -o -name '*.hpp' \) -print0 | \
    xargs -0 -n1 clang-format --dry-run --Werror

# --- clang-tidy check ---
echo "Running clang-tidy..."
cmake -S "${SRC_DIR}" -B "${TIDY_DIR}" -G "Ninja" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

find "${SRC_DIR}/src" -type f \( -name '*.cpp' -o -name '*.cc' -o -name '*.h' -o -name '*.hpp' \) -print0 | \
    xargs -0 -n1 clang-tidy -p "${TIDY_DIR}" --header-filter='src/.*' --warnings-as-errors=*

find "${SRC_DIR}/include" -type f \( -name '*.h' -o -name '*.hpp' \) -print0 | \
    xargs -0 -n1 clang-tidy -p "${TIDY_DIR}" --header-filter='src/.*' --warnings-as-errors=*

# --- Build and install ---
echo "Configuring the build..."
cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" -G "Ninja" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}"

# Build the project with parallel jobs
NUM_JOBS="$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"
cmake --build "${BUILD_DIR}" --config Release -- -j"${NUM_JOBS}"

# Install the built files to the install directory
cmake --install "${BUILD_DIR}" --config Release

# Inform the user about completion
echo "Build and installation completed."
echo "Libraries and binaries installed to: ${INSTALL_DIR}"
