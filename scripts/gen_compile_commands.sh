#!/usr/bin/env bash
set -euo pipefail

# Absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/.."

TIDY_DIR="${SRC_DIR}/build/build_tidy"

echo "Generating compile_commands.json..."

rm -rf "${TIDY_DIR}"
mkdir -p "${TIDY_DIR}"

cmake -S "${SRC_DIR}" -B "${TIDY_DIR}" \
    -G Ninja \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_BUILD_TYPE=Debug

echo "compile_commands.json generated at: ${TIDY_DIR}/compile_commands.json"
