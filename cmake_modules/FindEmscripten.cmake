# - Try to find the Clang/LLVM executable
# Once done this will define
#
#  EMSCRIPTEN_FOUND       - system has Clang
#  EMSCRIPTEN_VERSION     - Clang version
#  EMSCRIPTEN_EXECUTABLE  - Clang executable
#
# Copyright (c) 2013, Vittorio Giovara <vittorio.giovara@gmail.com>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

find_program(EMSCRIPTEN_EXECUTABLE
        NAMES emcc
        PATHS /opt/local/bin /usr/local/bin /usr/bin)

if (EMSCRIPTEN_EXECUTABLE)
    execute_process(COMMAND ${EMSCRIPTEN_EXECUTABLE} -v
                    OUTPUT_VARIABLE EMSCRIPTEN_VERSION_OUTPUT
                    ERROR_VARIABLE EMSCRIPTEN_VERSION_ERROR
                    RESULT_VARIABLE EMSCRIPTEN_VERSION_RESULT
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    )

    if(${EMSCRIPTEN_VERSION_RESULT} EQUAL 0)
        string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" EMSCRIPTEN_VERSION "${EMSCRIPTEN_VERSION_OUTPUT}")
        string(REGEX REPLACE "([0-9]+\\.[0-9]+\\.[0-9]+)" "\\1" EMSCRIPTEN_VERSION "${EMSCRIPTEN_VERSION}")
    else()
        message(SEND_ERROR "Command \"${EMSCRIPTEN_EXECUTABLE} --version\" failed with output: ${EMSCRIPTEN_VERSION_ERROR}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Emscripten DEFAULT_MSG EMSCRIPTEN_EXECUTABLE EMSCRIPTEN_VERSION)
mark_as_advanced(EMSCRIPTEN_VERSION)

