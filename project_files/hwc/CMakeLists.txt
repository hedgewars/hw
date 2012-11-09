
if(CLANG)
    set(clang_executable ${CLANG})
else()
    find_program(clang_executable clang)
endif()

if (clang_executable)
    exec_program(${clang_executable} ARGS "-v" OUTPUT_VARIABLE clang_version_full)
    string(REGEX MATCH "[0-9]+\\.[0-9]+" clang_version_long "${clang_version_full}")
    string(REGEX REPLACE "([0-9]+\\.[0-9]+)" "\\1" clang_version "${clang_version_long}")
    message(STATUS "Found CLANG: ${clang_executable} (version ${clang_version})")
else()
    message(FATAL_ERROR "No LLVM/Clang compiler found (required for engine_c target)")
endif()


find_package(GLEW REQUIRED)


set(CMAKE_C_COMPILER ${clang_executable})

configure_file(${hedgewars_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/hwengine.c"
        COMMAND "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}"
        ARGS -n hwengine -i "${hedgewars_SOURCE_DIR}/hedgewars" -o "${CMAKE_CURRENT_BINARY_DIR}" -a ./
        DEPENDS pas2c
        )

add_custom_target(engine_c ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/hwengine.c")

add_subdirectory(rtl)

include_directories("${GLEW_INCLUDE_PATH}")
include_directories(rtl)

file(GLOB engine_src *.c)
add_executable(hwengine WIN32 ${engine_src})
add_dependencies(hwengine engine_c fpcrtl)
