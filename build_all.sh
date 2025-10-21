#!/usr/bin/env bash
set -euo pipefail  

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define build and install directories
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_DIR="${SCRIPT_DIR}/install"

# Remove old build/install directories and create new ones
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"

# Configure the CMake project
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DBUILD_EXAMPLES=ON \
    -DBUILD_TESTS=ON

# Build the project with parallel jobs
cmake --build "${BUILD_DIR}" --config Release -- -j"$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"

# Install the built files to the install directory
cmake --install "${BUILD_DIR}" --config Release

# Inform the user about completion
echo "Build and installation completed."
echo "Libraries and binaries installed to: ${INSTALL_DIR}"
