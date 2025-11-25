#!/usr/bin/env bash
set -euo pipefail

# Absolute path to the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/.."

TIDY_TESTS_DIR="${SRC_DIR}/build/build_tidy_tests"

echo "Generating compile_commands.json..."

rm -rf "${TIDY_TESTS_DIR}"
mkdir -p "${TIDY_TESTS_DIR}"

cmake -S "${SRC_DIR}" -B "${TIDY_TESTS_DIR}" \
    -G Ninja \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_STANDARD=20 \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTS=ON \
    -DBUILD_EXAMPLES=OFF

echo "compile_commands.json generated at: ${TIDY_TESTS_DIR}/compile_commands.json"
