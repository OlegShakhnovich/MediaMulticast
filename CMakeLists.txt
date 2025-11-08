cmake_minimum_required (VERSION 3.22)
project (upstreamer VERSION 0.1 LANGUAGES CXX)


set (CMAKE_CXX_STANDARD 20)
set (CMAKE_POSITION_INDEPENDENT_CODE ON)


option (BUILD_EXAMPLES "Build example binaries" ON)
option (BUILD_TESTS "Build unit tests" ON)
option (CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ------------------------------------------------------------
# Clang-Tidy integration
# ------------------------------------------------------------
find_program(CLANG_TIDY_EXE NAMES clang-tidy)

if(CLANG_TIDY_EXE)
    message(STATUS "Found clang-tidy: ${CLANG_TIDY_EXE}")
    set(CMAKE_CXX_CLANG_TIDY
        "${CLANG_TIDY_EXE}" "--extra-arg-before=--driver-mode=cl" "--header-filter=src/.*" "--warnings-as-errors=*"
    )
endif()

# ------------------------------------------------------------
# Subdirectories
# ------------------------------------------------------------
add_subdirectory (src/udp_streaming_lib)
add_subdirectory (src/udp_streamer)

if (BUILD_EXAMPLES)
    add_subdirectory (examples)
endif()


if (BUILD_TESTS)
    enable_testing ()
    add_subdirectory (tests)
endif()
