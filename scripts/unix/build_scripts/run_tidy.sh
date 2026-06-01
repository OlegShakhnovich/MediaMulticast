#!/bin/bash
set -euo pipefail

# Include common and config files
SCRIPT_DIR="$(dirname "$0")"
COMMON="$SCRIPT_DIR/../common/common.sh"
CONFIG="$SCRIPT_DIR/../common/config.sh"

# Source configuration and common functions
source "$CONFIG" || { echo "Failed to source config.sh" >&2; exit 1; }
source "$COMMON" || { echo "Failed to source common.sh" >&2; exit 1; }

# Function to run clang-tidy on src and include
run_tidy() {
    run_clang_tidy "$ROOT_DIR/.clang-tidy" "$TIDY_DIR" "OFF" "$SRC_DIR $INCLUDE_DIR"
}

# Execute the function and exit with its return code
run_tidy
exit $?