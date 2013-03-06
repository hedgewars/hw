# - Try to find the FreePascal executable
# Once done this will define
#
#  FREEPASCAL_FOUND       - system has Freepascal
#  FREEPASCAL_VERSION     - Freepascal version
#  FREEPASCAL_EXECUTABLE  - Freepascal executable
#
# Copyright (c) 2012, Bryan Dunsmore <dunsmoreb@gmail.com>
# Copyright (c) 2013, Vittorio Giovara <vittorio.giovara@gmail.com>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.


find_program(FREEPASCAL_EXECUTABLE
    NAMES fpc
    PATHS /opt/local/bin /usr/local/bin /usr/bin
    )

if (FREEPASCAL_EXECUTABLE)
    # check Freepascal version
    execute_process(COMMAND ${FREEPASCAL_EXECUTABLE} -iV
                    OUTPUT_VARIABLE FREEPASCAL_VERSION
                    ERROR_VARIABLE FREEPASCAL_VERSION_ERROR
                    RESULT_VARIABLE FREEPASCAL_VERSION_RESULT
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    )

    if(NOT ${FREEPASCAL_VERSION_RESULT} EQUAL 0)
        message(SEND_ERROR "Command \"${FREEPASCAL_EXECUTABLE} -iV\" failed with output: ${FREEPASCAL_VERSION_ERROR}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FreePascal DEFAULT_MSG FREEPASCAL_EXECUTABLE FREEPASCAL_VERSION)
mark_as_advanced(FREEPASCAL_VERSION)

