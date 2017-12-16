#libraries have already been searched in main CMakeLists.txt

include_directories(${LIBAV_INCLUDE_DIR})

add_library(avwrapper avwrapper.c)
set_target_properties(avwrapper PROPERTIES
                          VERSION 1.0
                          SOVERSION 1.0)
target_link_libraries(avwrapper ${LIBAV_LIBRARIES})
install(TARGETS avwrapper RUNTIME DESTINATION ${target_binary_install_dir}
                          LIBRARY DESTINATION ${target_library_install_dir}
                          ARCHIVE DESTINATION ${target_library_install_dir})

