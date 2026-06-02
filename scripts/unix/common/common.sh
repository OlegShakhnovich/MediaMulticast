#!/bin/bash

# Prevent double sourcing
if [ -n "${_COMMON_SH_LOADED:-}" ]; then
    return 0
fi
readonly _COMMON_SH_LOADED=1

# ------------------------------------------------------------
# Log an informational message to stdout
# Args: message text
# Returns: 0
# ------------------------------------------------------------
log_message() {
    echo "$*"
}

# ------------------------------------------------------------
# Log an error message to stderr
# Args: message text
# Returns: 0
# ------------------------------------------------------------
error_log() {
    echo "$*" >&2
}

# ------------------------------------------------------------
# Clean a directory (remove if exists)
# Args: directory path
# Returns: 0
# ------------------------------------------------------------
clean_dir() {
    local DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        rm -rf "$DIR_PATH"
    fi
}

# ------------------------------------------------------------
# Collect source files (.cpp .cc .h .hpp) from given directories
# Args: space-separated list of directories
# Output: list of absolute file paths, one per line (to stdout)
# Returns: 0 if at least one file found, 1 otherwise
# Warnings: printed to stderr for missing directories
# ------------------------------------------------------------
collect_source_files() {
    local COLLECT_DIRS="$1"
    local FILES=()
    for DIR in $COLLECT_DIRS; do
        if [ -d "$DIR" ]; then
            while IFS= read -r -d '' FILE; do
                FILES+=("$FILE")
            done < <(find "$DIR" -type f \( -name "*.cpp" -o -name "*.cc" -o -name "*.h" -o -name "*.hpp" \) -print0)
        else
            error_log "Warning: directory does not exist: $DIR"
        fi
    done
    if [ ${#FILES[@]} -eq 0 ]; then
        return 1
    fi
    printf "%s\n" "${FILES[@]}"
}

# ------------------------------------------------------------
# Check clang-format and apply if needed
# Uses global: SRC_DIR, INCLUDE_DIR, TESTS_DIR, CLANG_FORMAT
# Returns: 0 on success (no errors or after applying), 1 if file collection failed
# ------------------------------------------------------------
check_and_apply_clang_format() {
    local FORMAT_DIRS="$SRC_DIR $INCLUDE_DIR $TESTS_DIR"
    local FORMAT_ERRORS=0

    local FILES
    FILES=$(collect_source_files "$FORMAT_DIRS") || return $?

    log_message "Running clang-format check..."
    while IFS= read -r FILE; do
        if ! $CLANG_FORMAT --dry-run --Werror "$FILE" > /dev/null 2>&1; then
            FORMAT_ERRORS=1
            log_message "Formatting errors found in $FILE. Formatting will be applied."
        fi
    done <<< "$FILES"

    if [ $FORMAT_ERRORS -eq 1 ]; then
        log_message "Applying clang-format..."
        while IFS= read -r FILE; do
            $CLANG_FORMAT -i "$FILE"
        done <<< "$FILES"
        log_message "clang-format applied. Please check the changes."
    else
        log_message "All files are formatted correctly."
    fi
}

# ------------------------------------------------------------
# Generate compile_commands.json using CMake with Ninja
# Args: BUILD_DIR, BUILD_TESTS (ON/OFF)
# Uses global: ROOT_DIR, LLVM_BIN
# Returns: 0 on success, non-zero on failure
# ------------------------------------------------------------
update_compile_commands() {
    local BUILD_DIR="$1"
    local BUILD_TESTS="$2"

    check_and_apply_clang_format || return $?

    mkdir -p "$BUILD_DIR"

    cmake -S "$ROOT_DIR" -B "$BUILD_DIR" \
    -G "Ninja" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_CXX_COMPILER="$LLVM_BIN/clang++" \
    -DCMAKE_C_COMPILER="$LLVM_BIN/clang" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTS="$BUILD_TESTS"

    local cmake_ret=$?
    if [ $cmake_ret -ne 0 ]; then
        error_log "CMake configuration failed"
        return $cmake_ret
    fi

    if [ ! -f "$BUILD_DIR/compile_commands.json" ]; then
        error_log "compile_commands.json not found in $BUILD_DIR"
        return 1
    fi

    log_message "compile_commands.json updated at $BUILD_DIR/compile_commands.json"
}

# ------------------------------------------------------------
# Run clang-tidy on files from specified directories
# Args: CFG (path to .clang-tidy), BUILD_DIR, BUILD_TESTS, CHECK_DIRS
# Uses global: CLANG_TIDY
# Returns: 0 on success, non-zero on any error
# ------------------------------------------------------------
run_clang_tidy() {
    local CFG="$1"
    local BUILD_DIR="$2"
    local BUILD_TESTS="$3"
    local CHECK_DIRS="$4"

    update_compile_commands "$BUILD_DIR" "$BUILD_TESTS" || return $?

    local FILES
    FILES=$(collect_source_files "$CHECK_DIRS") || return $?

    while IFS= read -r FILE; do
        log_message "[clang-tidy] $FILE"
        if ! $CLANG_TIDY "$FILE" --config-file="$CFG" -p "$BUILD_DIR" --warnings-as-errors=*; then
            return $?
        fi
    done <<< "$FILES"

    log_message "clang-tidy finished successfully."
}

# ------------------------------------------------------------
# Get number of CPU cores
# Output: number of cores (to stdout)
# Returns: 0
# ------------------------------------------------------------
get_num_jobs() {
    local NUM_JOBS=1
    if command -v nproc &> /dev/null; then
        NUM_JOBS=$(nproc)
    elif [ -f /proc/cpuinfo ]; then
        NUM_JOBS=$(grep -c ^processor /proc/cpuinfo)
    elif command -v sysctl &> /dev/null; then
        NUM_JOBS=$(sysctl -n hw.ncpu)
    fi
    echo "$NUM_JOBS"
}
