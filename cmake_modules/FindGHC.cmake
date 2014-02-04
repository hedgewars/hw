# - Try to find the Glasgow Haskell Compiler executable
# Once done this will define
#
#  GHC_FOUND       - system has GHC
#  GHC_VERSION     - GHC version
#  GHC_EXECUTABLE  - GHC executable
#
# Copyright (c) 2013, Vittorio Giovara <vittorio.giovara@gmail.com>
#
# Redistribution and use is allowed according to the terms of the BSD license.
# For details see the accompanying COPYING-CMAKE-SCRIPTS file.


find_program(GHC_EXECUTABLE
    NAMES ghc
    PATHS /opt/local/bin /usr/local/bin /usr/bin
    )

if (GHC_EXECUTABLE)
    # check ghc version
    execute_process(COMMAND ${GHC_EXECUTABLE} -V
                    OUTPUT_VARIABLE GHC_VERSION_OUTPUT
                    ERROR_VARIABLE GHC_VERSION_ERROR
                    RESULT_VARIABLE GHC_VERSION_RESULT
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    )

    if(${GHC_VERSION_RESULT} EQUAL 0)
        string(REGEX MATCH "([0-9]+)" GHC_VERSION ${GHC_VERSION_OUTPUT})
    else()
        message(SEND_ERROR "Command \"${GHC_EXECUTABLE} -V\" failed with output: ${GHC_VERSION_ERROR}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GHC DEFAULT_MSG GHC_EXECUTABLE GHC_VERSION)
mark_as_advanced(GHC_VERSION)

