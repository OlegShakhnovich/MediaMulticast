cmake_minimum_required(VERSION 3.22)
project(UdpStreamingLibTests LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

# GoogleTest
include(FetchContent)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG release-1.12.1
)
FetchContent_MakeAvailable(googletest)

include_directories(${GTEST_INCLUDE_DIRS} ..)

add_executable(test_udp_streaming_lib test_udp_streaming_lib.cpp)
target_link_libraries(test_udp_streaming_lib PRIVATE udp_streaming_lib GTest::gtest GTest::gtest_main)

if(CMAKE_CXX_CLANG_TIDY)
  set_target_properties(gtest gtest_main gmock gmock_main
    PROPERTIES
    CXX_CLANG_TIDY ""
  )
endif()

