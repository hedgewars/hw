
configure_file(${hedgewars_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/hwengine.c"
        COMMAND "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}"
        ARGS -n hwengine -i "${hedgewars_SOURCE_DIR}/hedgewars" -o "${CMAKE_CURRENT_BINARY_DIR}" -a ./
        DEPENDS pas2c
        )

add_custom_target(engine_c ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/hwengine.c")

add_subdirectory(rtl)

find_package(GLEW REQUIRED)
message("${GLEW_INCLUDE_PATH}")

include_directories(rtl)
file(GLOB engine_src *.c)
add_executable(hwengine WIN32 ${engine_src})
add_dependencies(hwengine engine_c fpcrtl)
