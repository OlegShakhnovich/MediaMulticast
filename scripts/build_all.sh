#!/usr/bin/env bash
set -euo pipefail  

# Get the absolute path of the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Assume the source root is one level above scripts folder
SRC_DIR="${SCRIPT_DIR}/.."

# Define build and install directories
BUILD_DIR="${SRC_DIR}/build"
INSTALL_DIR="${SRC_DIR}/install"

# Remove old build/install directories and create new ones
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"

# Configure the CMake project
cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DBUILD_EXAMPLES=ON \
    -DBUILD_TESTS=ON

# Build the project with parallel jobs
NUM_JOBS="$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)"
cmake --build "${BUILD_DIR}" --config Release -- -j"${NUM_JOBS}"

# Install the built files to the install directory
cmake --install "${BUILD_DIR}" --config Release

# Inform the user about completion
echo "Build and installation completed."
echo "Libraries and binaries installed to: ${INSTALL_DIR}"
