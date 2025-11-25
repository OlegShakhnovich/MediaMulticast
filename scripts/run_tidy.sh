#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/.."
TIDY_DIR="${SRC_DIR}/build/build_tidy"

CLANG_TIDY=$(command -v clang-tidy)

if [[ ! -f "${TIDY_DIR}/compile_commands.json" ]]; then
    echo "compile_commands.json not found in ${TIDY_DIR}"
    echo "Run gen_compile_commands.sh first."
    exit 1
fi

echo "Running clang-tidy with compile_commands.json in ${TIDY_DIR}"

find "${SRC_DIR}/src" "${SRC_DIR}/include" -type f \
    \( -name '*.cpp' -o -name '*.cc' -o -name '*.hpp' -o -name '*.h' \) \
    -print0 | xargs -0 -n1 "${CLANG_TIDY}" -p "${TIDY_DIR}"
