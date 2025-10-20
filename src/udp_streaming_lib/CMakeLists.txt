add_library (udp_streaming_lib SHARED
    file_reader/file_reader.cpp
    header_parser/header_parser.cpp
    queueing/queue.cpp
    timed_streaming/timer.cpp
    networking/udp_multicast.cpp
)


set (UDP_STREAMING_LIB_HEADERS
    ${CMAKE_CURRENT_SOURCE_DIR}/file_reader/file_reader.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/header_parser/header_parser.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/queueing/queue.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/timed_streaming/timer.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/networking/udp_multicast.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/udp_streaming_lib_export.hpp
)


target_compile_definitions (udp_streaming_lib PRIVATE UDP_STREAMING_LIB_EXPORTS)


target_include_directories (udp_streaming_lib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
)


target_compile_features (udp_streaming_lib PUBLIC cxx_std_20)


target_compile_definitions (udp_streaming_lib PRIVATE
    $<$<CONFIG:DEBUG>:DEBUG_BUILD>
    $<$<CONFIG:RELEASE>:NDEBUG>
    UDP_STREAMING_LIB_EXPORTS
)


if (MSVC)
   target_compile_options (udp_streaming_lib PRIVATE /W4 /permissive-)
else ()
   target_compile_options (udp_streaming_lib PRIVATE -Wall -Wextra -pedantic)
endif()


if (WIN32)
    target_compile_definitions (udp_streaming_lib PRIVATE PLATFORM_WINDOWS)
elseif (APPLE)
    target_compile_definitions (udp_streaming_lib PRIVATE PLATFORM_MAC)
else()
    target_compile_definitions (udp_streaming_lib PRIVATE PLATFORM_LINUX)
endif()


install (TARGETS udp_streaming_lib
    EXPORT udp_streaming_libTargets
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    INCLUDES DESTINATION include
)


install (FILES ${UDP_STREAMING_LIB_HEADERS} DESTINATION include)


install (EXPORT udp_streaming_libTargets
    FILE udp_streaming_libTargets.cmake
    NAMESPACE upstreamer::
    DESTINATION lib/cmake/upstreamer
)


include (CMakePackageConfigHelpers)


write_basic_package_version_file (
    "${CMAKE_CURRENT_BINARY_DIR}/upstreamerConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file (
    "${CMAKE_SOURCE_DIR}/cmake/Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/upstreamerConfig.cmake"
    INSTALL_DESTINATION lib/cmake/upstreamer
)

install (FILES
    "${CMAKE_CURRENT_BINARY_DIR}/upstreamerConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/upstreamerConfigVersion.cmake"
    DESTINATION lib/cmake/upstreamer
)



source_group (TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES
    file_reader/file_reader.cpp
    header_parser/header_parser.cpp
    queueing/queue.cpp
    timed_streaming/timer.cpp
    networking/udp_multicast.cpp
)