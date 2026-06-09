#!/bin/bash
set -euo pipefail

# Include common and config files
SCRIPT_DIR="$(dirname "$0")"
COMMON="$SCRIPT_DIR/../common/common.sh"
CONFIG="$SCRIPT_DIR/../common/config.sh"

# Source configuration and common functions
source "$CONFIG" || { echo "Failed to source config.sh" >&2; exit 1; }
source "$COMMON" || { echo "Failed to source common.sh" >&2; exit 1; }

# Function to build the project using Ninja
build_with_ninja() {
    log_message "Starting update_compile_commands..."
    local BUILD_DIR="$TIDY_DIR"
    
    update_compile_commands "$BUILD_DIR" "OFF" || return $?
    
    # Get the number of available CPU cores
    local NUM_JOBS
    NUM_JOBS=$(get_num_jobs)

    # Build the project
    log_message "Building with $NUM_JOBS jobs..."
    cmake --build "$BUILD_DIR" -- -j"$NUM_JOBS" || {
        error_log "Build failed."
        return $?
    }

    cmake --install "$BUILD_DIR" --prefix "$INSTALL_DIR/ninja" || {
        error_log "Installation failed."
        return $?
    }

    log_message "Build and installation completed successfully."
}

# Execute the function and exit with its return code
build_with_ninja
exit $?
