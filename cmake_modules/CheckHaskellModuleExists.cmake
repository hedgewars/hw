# Based on CheckLibraryExists.cmake from CMake
#=============================================================================
# Copyright 2002-2009 Kitware, Inc.
#
# Distributed under the OSI-approved BSD License
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================

macro(CHECK_HASKELL_MODULE_EXISTS MODULE FUNCTION PARAMCOUNT LIBRARY)
  set(VARIABLE "HS_MODULE_${LIBRARY}_${FUNCTION}")
  if(${VARIABLE} MATCHES ^${VARIABLE}$)
    message(STATUS "Looking for ${FUNCTION} in ${MODULE}")

    set(PARAMETERS "")

    if(PARAMCOUNT GREATER 0)
        foreach(__TRASH__ RANGE 1 ${PARAMCOUNT})
            set(PARAMETERS "${PARAMETERS} undefined")
        endforeach()
    endif()

    set(PARAMETERS "")

    execute_process(COMMAND ${GHC_EXECUTABLE}
                    "-DMODULE=${MODULE}"
                    "-DFUNCTION=${FUNCTION}"
                    "-DPARAMETERS=${PARAMETERS}"
                    -cpp
                    -c "${CMAKE_MODULE_PATH}/checkModule.hs"
                    RESULT_VARIABLE COMMAND_RESULT
                    ERROR_VARIABLE BUILD_ERROR
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    )
    if(${COMMAND_RESULT} EQUAL 0)
      message(STATUS "Looking for ${FUNCTION} in ${MODULE} - found")
      set(${VARIABLE} 1 CACHE INTERNAL "Have module ${MODULE}")
      file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
        "Determining if the function ${FUNCTION} exists in the ${MODULE} passed\n\n")
    else()
      message(STATUS "Looking for ${FUNCTION} in ${MODULE} - not found")
      set(${VARIABLE} "" CACHE INTERNAL "Have module ${MODULE}")
      file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
        "Determining if the function ${FUNCTION} exists in the ${MODULE} "
        "failed with the following output:\n"
        "${BUILD_ERROR}\n\n")
      message(FATAL_ERROR "Haskell library '${LIBRARY}' required")
    endif()
  endif()
endmacro()
