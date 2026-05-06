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
