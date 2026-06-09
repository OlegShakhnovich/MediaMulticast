cmake_minimum_required (VERSION 3.22)
project (upstreamer VERSION 0.1 LANGUAGES CXX)


set (CMAKE_CXX_STANDARD 20)
set (CMAKE_POSITION_INDEPENDENT_CODE ON)
option (CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ------------------------------------------------------------
# Options for pre‑build clang-tidy / clang-format
# ------------------------------------------------------------
option (ENABLE_CLANG_TIDY_PRE_BUILD "Run clang-tidy and clang-format as a pre‑build step" OFF)
option (ENABLE_TIDY_FOR_MAIN "Run clang-tidy on src/ and include/ (only relevant if ENABLE_CLANG_TIDY_PRE_BUILD=ON)" ON)

# ------------------------------------------------------------
# Preparing pre-build dependencies for Visual Studio
# ------------------------------------------------------------
if (WIN32)
    if (ENABLE_CLANG_TIDY_PRE_BUILD)
        # Paths to the wrapper scripts (relative to project root)
        set (TIDY_SCRIPT_MAIN  "${CMAKE_CURRENT_SOURCE_DIR}/scripts/windows/build_scripts/run_tidy.bat")
        set (TIDY_SCRIPT_TESTS "${CMAKE_CURRENT_SOURCE_DIR}/scripts/windows/build_scripts/run_tidy_tests.bat")

        # Create main tidy target only if requested (ENABLE_TIDY_FOR_MAIN=ON)
        if (ENABLE_TIDY_FOR_MAIN)
            add_custom_target (run_clang_tidy_main
                COMMAND ${CMAKE_COMMAND} -E echo "=== Running clang-tidy on main code ==="
                COMMAND "${TIDY_SCRIPT_MAIN}"
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                COMMENT "Run clang-format + clang-tidy for src/ and include/"
                VERBATIM
            )
        endif ()

        # Create test tidy target only if tests are enabled (BUILD_TESTS=ON)
        if (BUILD_TESTS)
            add_custom_target (run_clang_tidy_tests
                COMMAND ${CMAKE_COMMAND} -E echo "=== Running clang-tidy on tests ==="
                COMMAND "${TIDY_SCRIPT_TESTS}"
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                COMMENT "Run clang-format + clang-tidy for tests/"
                VERBATIM
            )
        endif ()
    endif ()
endif ()

# ------------------------------------------------------------
# Subdirectories
# ------------------------------------------------------------
add_subdirectory (src/udp_streaming_lib)
add_subdirectory (src/udp_streamer)

# ------------------------------------------------------------
# Optional examples
# ------------------------------------------------------------
if (BUILD_EXAMPLES)
    add_subdirectory (examples)
endif ()

# ------------------------------------------------------------
# Tests
# ------------------------------------------------------------
if (BUILD_TESTS)
    enable_testing ()
    add_subdirectory (tests EXCLUDE_FROM_ALL)
endif ()

# ------------------------------------------------------------
# Attach pre‑build dependencies for Visual Studio (must be after add_subdirectory)
# ------------------------------------------------------------
if (WIN32)
    if (ENABLE_CLANG_TIDY_PRE_BUILD)
        # Main library and executable depend on the main tidy target if it exists
        if (TARGET run_clang_tidy_main)
            if (TARGET udp_streaming_lib)
                add_dependencies (udp_streaming_lib run_clang_tidy_main)
            endif ()
            if (TARGET udp_streamer)
                add_dependencies (udp_streamer run_clang_tidy_main)
            endif ()
        endif ()

        # Tests depend on the test tidy target if it exists, and optionally on the main tidy target.
        # Note: run_clang_tidy_tests exists only when BUILD_TESTS=ON.
        if (TARGET run_clang_tidy_tests)
            # The test executable name as defined in tests/CMakeLists.txt
            set (TEST_TARGET_NAME "test_udp_streaming_lib")
            if (TARGET ${TEST_TARGET_NAME})
                if (TARGET run_clang_tidy_main)
                    # Both main and test tidy checks will run before building tests
                    add_dependencies (${TEST_TARGET_NAME} run_clang_tidy_main run_clang_tidy_tests)
                else ()
                    # Only test tidy checks (useful for "tidy only for tests" mode)
                    add_dependencies (${TEST_TARGET_NAME} run_clang_tidy_tests)
                endif ()
            else ()
                message (WARNING "Test target '${TEST_TARGET_NAME}' not found; pre‑build tidy will not be attached to tests.")
            endif ()
        endif ()
    endif ()
endif ()

