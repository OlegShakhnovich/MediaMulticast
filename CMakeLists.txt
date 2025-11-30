cmake_minimum_required (VERSION 3.22)
project (upstreamer VERSION 0.1 LANGUAGES CXX)


set (CMAKE_CXX_STANDARD 20)
set (CMAKE_POSITION_INDEPENDENT_CODE ON)
option (CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ------------------------------------------------------------
# Subdirectories
# ------------------------------------------------------------
add_subdirectory (src/udp_streaming_lib)
add_subdirectory (src/udp_streamer)

# ------------------------------------------------------------
# Clang-Tidy integration
# ------------------------------------------------------------
if (MSVC)
    set (CMAKE_RULE_LAUNCH_COMPILE "${CMAKE_SOURCE_DIR}/scripts/msvc_tidy_wrapper.bat")
endif()


find_program(CLANG_TIDY_EXE NAMES clang-tidy)
if(CLANG_TIDY_EXE AND NOT MSVC)
    message(STATUS "Enabling clang-tidy: ${CLANG_TIDY_EXE}")
    set(CLANG_TIDY_COMMAND "${CLANG_TIDY_EXE};--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy")
    set_target_properties(udp_streaming_lib PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")
    set_target_properties(udp_streamer PROPERTIES CXX_CLANG_TIDY "${CLANG_TIDY_COMMAND}")
endif()

# ------------------------------------------------------------
# Optional examples
# ------------------------------------------------------------
if (BUILD_EXAMPLES)
    add_subdirectory (examples)
endif()

# ------------------------------------------------------------
# Tests
# ------------------------------------------------------------
if (BUILD_TESTS)
    enable_testing ()
    add_subdirectory(tests EXCLUDE_FROM_ALL)
endif()
