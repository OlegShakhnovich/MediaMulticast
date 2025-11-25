cmake_minimum_required(VERSION 3.22)
project(UdpStreamingLibTests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)

# ------------------------------------------------------------
# GoogleTest
# ------------------------------------------------------------
set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
set(INSTALL_GMOCK OFF CACHE BOOL "" FORCE)

include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG release-1.12.1
)
FetchContent_MakeAvailable(googletest)

include_directories(${GTEST_INCLUDE_DIRS} ..)

# ------------------------------------------------------------
# Test executable
# ------------------------------------------------------------
add_executable(test_udp_streaming_lib test_udp_streaming_lib.cpp)
target_link_libraries(test_udp_streaming_lib PRIVATE udp_streaming_lib GTest::gtest GTest::gtest_main)

if(CMAKE_CXX_CLANG_TIDY)
    set_target_properties(gtest gtest_main gmock gmock_main PROPERTIES
        CXX_CLANG_TIDY ""
    )
endif()

# ------------------------------------------------------------
# Enable clang-tidy for test_udp_streaming_lib if available
# ------------------------------------------------------------
find_program(CLANG_TIDY_EXE NAMES clang-tidy)

if(CLANG_TIDY_EXE AND NOT MSVC)
    set_target_properties(test_udp_streaming_lib PROPERTIES
        CXX_CLANG_TIDY
            "${CLANG_TIDY_EXE};--config-file=${CMAKE_CURRENT_SOURCE_DIR}/.clang-tidy"
    )
endif()
