#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/.."
TIDY_DIR="${SRC_DIR}/build/build_tidy_tests"
CLANG_TIDY_CONFIG="${SRC_DIR}/tests/.clang-tidy"

CLANG_TIDY=$(command -v clang-tidy)

if [[ ! -f "${TIDY_DIR}/compile_commands.json" ]]; then
    echo "compile_commands.json not found in ${TIDY_DIR}"
    echo "Run gen_compile_commands.sh first."
    exit 1
fi

echo "Running clang-tidy with compile_commands.json in ${TIDY_DIR}" using config ${CLANG_TIDY_CONFIG}"

find "${SRC_DIR}/tests" -type f \
    \( -name '*.cpp' -o -name '*.cc' -o -name '*.hpp' -o -name '*.h' \) \
    -print0 | xargs -0 -n1 "${CLANG_TIDY}" -p "${TIDY_DIR}" --config-file="${CLANG_TIDY_CONFIG}"
