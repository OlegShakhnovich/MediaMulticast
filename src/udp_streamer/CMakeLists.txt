add_executable (udp_streamer main.cpp)


add_custom_command (TARGET udp_streamer POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:udp_streaming_lib>
        $<TARGET_FILE_DIR:udp_streamer>
)


target_compile_features (udp_streamer PUBLIC cxx_std_20)


target_compile_definitions (udp_streamer PRIVATE
    $<$<CONFIG:DEBUG>:DEBUG_BUILD>
    $<$<CONFIG:RELEASE>:NDEBUG>
)


if(MSVC)
    target_compile_options (udp_streamer PRIVATE /W4 /permissive- /EHsc /WX)
else()
    target_compile_options (udp_streamer PRIVATE -Wall -Wextra -pedantic -Werror)
endif()


target_link_libraries (udp_streamer PRIVATE udp_streaming_lib)


target_include_directories (udp_streamer PRIVATE
    ${PROJECT_SOURCE_DIR}/include
)


source_group (TREE ${CMAKE_CURRENT_SOURCE_DIR} FILES main.cpp)
