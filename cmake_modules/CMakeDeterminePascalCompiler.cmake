# Determine the compiler to use for Pascal programs
# NOTE, a generator may set CMAKE_Pascal_COMPILER before
# loading this file to force a compiler.
# use environment variable Pascal first if defined by user, next use
# the cmake variable CMAKE_GENERATOR_PASCAL which can be defined by a generator
# as a default compiler

IF(NOT CMAKE_Pascal_COMPILER)

  # prefer the environment variable FPC
  IF($ENV{FPC} MATCHES ".+")
    GET_FILENAME_COMPONENT(CMAKE_Pascal_COMPILER_INIT $ENV{FPC} PROGRAM PROGRAM_ARGS CMAKE_Pascal_FLAGS_ENV_INIT)
    IF(CMAKE_Pascal_FLAGS_ENV_INIT)
      SET(CMAKE_Pascal_COMPILER_ARG1 "${CMAKE_Pascal_FLAGS_ENV_INIT}" CACHE STRING "First argument to Pascal compiler")
    ENDIF(CMAKE_Pascal_FLAGS_ENV_INIT)
    IF(EXISTS ${CMAKE_Pascal_COMPILER_INIT})
    ELSE(EXISTS ${CMAKE_Pascal_COMPILER_INIT})
      MESSAGE(FATAL_ERROR "Could not find compiler set in environment variable FPC:\n$ENV{FPC}.")
    ENDIF(EXISTS ${CMAKE_Pascal_COMPILER_INIT})
  ENDIF($ENV{FPC} MATCHES ".+")

  # next try prefer the compiler specified by the generator
  IF(CMAKE_GENERATOR_PASCAL)
    IF(NOT CMAKE_Pascal_COMPILER_INIT)
      SET(CMAKE_Pascal_COMPILER_INIT ${CMAKE_GENERATOR_PASCAL})
    ENDIF(NOT CMAKE_Pascal_COMPILER_INIT)
  ENDIF(CMAKE_GENERATOR_PASCAL)

  # finally list compilers to try
  IF(CMAKE_Pascal_COMPILER_INIT)
    SET(CMAKE_Pascal_COMPILER_LIST ${CMAKE_Pascal_COMPILER_INIT})
  ELSE(CMAKE_Pascal_COMPILER_INIT)
    SET(CMAKE_Pascal_COMPILER_LIST fpc)
  ENDIF(CMAKE_Pascal_COMPILER_INIT)

  # Find the compiler.
  FIND_PROGRAM(CMAKE_Pascal_COMPILER NAMES ${CMAKE_Pascal_COMPILER_LIST} DOC "Pascal compiler")
  IF(CMAKE_Pascal_COMPILER_INIT AND NOT CMAKE_Pascal_COMPILER)
    SET(CMAKE_Pascal_COMPILER "${CMAKE_Pascal_COMPILER_INIT}" CACHE FILEPATH "Pascal compiler" FORCE)
  ENDIF(CMAKE_Pascal_COMPILER_INIT AND NOT CMAKE_Pascal_COMPILER)
ENDIF(NOT CMAKE_Pascal_COMPILER)
MARK_AS_ADVANCED(CMAKE_Pascal_COMPILER)

GET_FILENAME_COMPONENT(COMPILER_LOCATION "${CMAKE_Pascal_COMPILER}" PATH)

# configure variables set in this file for fast reload later on
if(${CMAKE_VERSION} VERSION_LESS 2.8.10)
  CONFIGURE_FILE(${CMAKE_MODULE_PATH}/CMakePascalCompiler.cmake.in
                 "${CMAKE_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/CMakePascalCompiler.cmake"
                 IMMEDIATE )
else(${CMAKE_VERSION} VERSION_LESS 2.8.10)
  CONFIGURE_FILE(${CMAKE_MODULE_PATH}/CMakePascalCompiler.cmake.in
                "${CMAKE_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${CMAKE_VERSION}/CMakePascalCompiler.cmake"
                 IMMEDIATE )
endif(${CMAKE_VERSION} VERSION_LESS 2.8.10)

SET(CMAKE_Pascal_COMPILER_ENV_VAR "FPC")
