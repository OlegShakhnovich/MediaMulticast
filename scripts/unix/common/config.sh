#!/bin/bash
set -euo pipefail

# Configuration settings

REQUIRED_LLVM_VERSION="21.1.6"

# Function to check version of a given LLVM tool
# Returns 0 on success, 1 on failure (prints error to stderr)
check_llvm_tool_version() {
    local tool_path="$1"
    local tool_name="$2"

    if [ ! -x "$tool_path" ]; then
        echo "Error: $tool_name not found at $tool_path" >&2
        return 1
    fi

    # Get version string (the line, which have a version)
    local version_line
    version_line=$("$tool_path" --version 2>/dev/null | grep -iE 'version[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+' | head -n1) || true
    if [ -z "$version_line" ]; then
        echo "Error: Could not retrieve version from $tool_name" >&2
        return 1
    fi

    # Extract semantic version (digits.digits.digits)
    local actual_version
    actual_version=$(echo "$version_line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1) || true
    if [ -z "$actual_version" ]; then
        echo "Error: Could not parse version from '$version_line'" >&2
        return 1
    fi

    if [ "$actual_version" != "$REQUIRED_LLVM_VERSION" ]; then
        echo "Error: Unsupported $tool_name version: $actual_version" >&2
        echo "       Required version: $REQUIRED_LLVM_VERSION" >&2
        return 1
    fi

    echo "Info: $tool_name version $actual_version (OK)" >&2
    return 0
}

# LLVM binaries (adjust path to your system)
if [ -d "/usr/local/llvm/bin" ]; then
    LLVM_BIN="/usr/local/llvm/bin"
elif [ -d "/usr/local/opt/llvm/bin" ]; then
    LLVM_BIN="/usr/local/opt/llvm/bin"
else
    LLVM_BIN="/usr/bin"
fi

CLANG_TIDY="${LLVM_BIN}/clang-tidy"
CLANG_FORMAT="${LLVM_BIN}/clang-format"

# Validate LLVM tools version
check_llvm_tool_version "$CLANG_FORMAT" "clang-format" || return 1
check_llvm_tool_version "$CLANG_TIDY" "clang-tidy" || return 1

# Get absolute path to script directory and root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Build directories
TIDY_DIR="${ROOT_DIR}/build/build_tidy"
TIDY_TESTS_DIR="${ROOT_DIR}/build/build_tidy_tests"
INSTALL_DIR="${ROOT_DIR}/install"
INCLUDE_DIR="${ROOT_DIR}/include"
SRC_DIR="${ROOT_DIR}/src"
TESTS_DIR="${ROOT_DIR}/tests"
