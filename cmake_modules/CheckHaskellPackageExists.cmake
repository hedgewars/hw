# Checks if a given Haskell package exists (using ghc-pkg)
# and fails if it's missing.
# Loosely based on CheckLibraryExists.cmake from CMake.
#=============================================================================
# Copyright 2002-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================

macro(CHECK_HASKELL_PACKAGE_EXISTS PACKAGE MODULE FUNCTION PARAMCOUNT)
# NOTE: MODULE, FUNCTION and PARAMCOUNT are curretly ignored.
# TODO: Either implement these or drop?

  set(VARIABLE "HS_PACKAGE_${PACKAGE}")
  if(NOT (${VARIABLE} EQUAL "1"))
    message(STATUS "Looking for Haskell package ${PACKAGE} ...")

    execute_process(COMMAND ${GHC_PKG_EXECUTABLE}
                    "latest"
                    ${PACKAGE}
                    "--simple-output"
                    RESULT_VARIABLE COMMAND_RESULT
                    ERROR_VARIABLE BUILD_ERROR
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    OUTPUT_QUIET
                    )

    if(${COMMAND_RESULT} EQUAL 0)
      message(STATUS "Looking for Haskell package ${PACKAGE} - found")
      set(${VARIABLE} "1" CACHE INTERNAL "Have package ${PACKAGE}")
      file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
        "Determining if the Haskell package ${PACKAGE} exists has passed\n\n")
    else()
      message(STATUS "Looking for Haskell package ${PACKAGE} - not found")
      set(${VARIABLE} "0" CACHE INTERNAL "Have package ${PACKAGE}")
      file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
        "Determining if the Haskell package ${PACKAGE} "
        "exists failed with the following output:\n"
        "${BUILD_ERROR}\n\n")
      message(FATAL_ERROR "Haskell package '${PACKAGE}' required")
    endif()
  endif()
endmacro()
