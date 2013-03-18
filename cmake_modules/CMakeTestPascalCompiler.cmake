# This file is used by EnableLanguage in cmGlobalGenerator to determine that
# the FreePascal can actually compile and link the most basic of programs.
# If not, a fatal error is set, cmake stops processing commands and will not
# generate any makefiles or projects.

IF(NOT CMAKE_Pascal_COMPILER_WORKS)
  MESSAGE(STATUS "Check for working Pascal compiler: ${CMAKE_Pascal_COMPILER}")
  FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CMakeTmp/testpascalcompiler.pas
  "program testPascalCompiler;
   begin
   end.
  ")

  FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CMakeTmp/CMakeLists.txt
  "set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake_modules)
   set(CMAKE_VERBOSE_MAKEFILE ON CACHE BOOL \"\" FORCE)
   project(test Pascal)
   add_executable(testpascalcompiler testpascalcompiler.pas)
  ")

# To avoid try_compile recurse error, use any binary directory other
# than ${CMAKE_BINARY_DIR}. The choice of
# bindir = ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp is
# especially advantageous since it makes an in-source build which
# means that no special variables need to be set to find files.
  try_compile(CMAKE_Pascal_COMPILER_WORKS
              ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CMakeTmp
              ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CMakeTmp
              projectName
              OUTPUT_VARIABLE RESULT_OUTPUT
              )
  SET(PASCAL_TEST_WAS_RUN 1)
ENDIF(NOT CMAKE_Pascal_COMPILER_WORKS)

IF(NOT CMAKE_Pascal_COMPILER_WORKS)
  MESSAGE(STATUS "Check for working Pascal compiler: ${CMAKE_Pascal_COMPILER} -- broken")
  FILE(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CMakeError.log
    "Determining if the Pascal compiler works failed with "
    "the following output:\n${RESULT_OUTPUT}\n\n")
  MESSAGE(FATAL_ERROR "The Pascal builder \"${CMAKE_Pascal_COMPILER}\" "
    "is not able to compile and link a simple test program.\nIt fails "
    "with the following output:\n ${RESULT_OUTPUT}\n\n"
    "CMake will not be able to correctly generate this project.")
ELSE(NOT CMAKE_Pascal_COMPILER_WORKS)
  IF(PASCAL_TEST_WAS_RUN)
    MESSAGE(STATUS "Check for working Pascal compiler: ${CMAKE_Pascal_COMPILER} -- works")
    FILE(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
      "Determining if the Pascal compiler works passed with "
      "the following output:\n${RESULT_OUTPUT}\n\n")
  ENDIF(PASCAL_TEST_WAS_RUN)
  SET(CMAKE_Pascal_COMPILER_WORKS 1 CACHE INTERNAL "")
ENDIF(NOT CMAKE_Pascal_COMPILER_WORKS)
