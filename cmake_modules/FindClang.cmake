# - Try to find the Clang/LLVM executable
# Once done this will define
#
#  CLANG_FOUND       - system has Clang
#  CLANG_VERSION     - Clang version
#  CLANG_EXECUTABLE  - Clang executable
#
# Copyright (c) 2013, Vittorio Giovara <vittorio.giovara@gmail.com>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.

find_program(CLANG_EXECUTABLE
        NAMES clang-mp-3.3 clang-mp-3.2 clang-mp-3.1 clang-mp-3.0 clang
        PATHS /opt/local/bin /usr/local/bin /usr/bin)

if (CLANG_EXECUTABLE)
    execute_process(COMMAND ${CLANG_EXECUTABLE} --version
                    OUTPUT_VARIABLE CLANG_VERSION_OUTPUT
                    ERROR_VARIABLE CLANG_VERSION_ERROR
                    RESULT_VARIABLE CLANG_VERSION_RESULT
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    )

    if(${CLANG_VERSION_RESULT} EQUAL 0)
        string(REGEX MATCH "[0-9]+\\.[0-9]+" CLANG_VERSION "${CLANG_VERSION_OUTPUT}")
        string(REGEX REPLACE "([0-9]+\\.[0-9]+)" "\\1" CLANG_VERSION "${CLANG_VERSION}")
    else()
        message(SEND_ERROR "Command \"${CLANG_EXECUTABLE} --version\" failed with output: ${CLANG_VERSION_ERROR}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Clang DEFAULT_MSG CLANG_EXECUTABLE CLANG_VERSION)
mark_as_advanced(CLANG_VERSION)

