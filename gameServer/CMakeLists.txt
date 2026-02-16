cmake_minimum_required(VERSION 3.19)

if(POLICY CMP0177)
  cmake_policy(SET CMP0177 NEW)
endif()

project(hedgewars-server)

find_program(CABAL_EXECUTABLE cabal REQUIRED)

option(BUILD_OFFICIAL_SERVER "Build with official server features" OFF)

set(SERVER_EXECUTABLE_NAME "hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}")
set(SERVER_OUTPUT_PATH "${CMAKE_CURRENT_BINARY_DIR}/${SERVER_EXECUTABLE_NAME}")
set(CABAL_DIST_DIR "${CMAKE_CURRENT_BINARY_DIR}/cabal-dist")

if(BUILD_OFFLINE)
    list(APPEND CABAL_FLAGS "--offline")
endif()

if(BUILD_OFFICIAL_SERVER)
    list(APPEND CABAL_FLAGS "--flags=officialServer")
else()
    list(APPEND CABAL_FLAGS "--flags=-officialServer")
endif()

message(STATUS "Checking Haskell dependencies with Cabal...")

execute_process(
    COMMAND ${CABAL_EXECUTABLE}
            v2-build
            exe:hedgewars-server
            --only-configure
            --dry-run
            --builddir=${CABAL_DIST_DIR}
            ${CABAL_FLAGS}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    RESULT_VARIABLE CABAL_CHECK_EXIT_CODE
    OUTPUT_VARIABLE CABAL_CHECK_OUTPUT
    ERROR_VARIABLE CABAL_CHECK_ERROR
)

if(NOT CABAL_CHECK_EXIT_CODE EQUAL 0)
    # Print the error from Cabal so the user knows which package is missing/conflict
    message(WARNING "${CABAL_CHECK_OUTPUT}")
    message(FATAL_ERROR "Cabal dependency check failed! See output above for missing packages or conflicts.\nError details:\n${CABAL_CHECK_ERROR}")
else()
    message(STATUS "Haskell dependencies are valid.")
endif()

add_custom_target(hedgewars-server ALL
    COMMAND ${CABAL_EXECUTABLE} 
            v2-build
            exe:hedgewars-server
            --builddir=${CABAL_DIST_DIR}
            ${CABAL_FLAGS}

    COMMAND ${CABAL_EXECUTABLE} 
             v2-install
             exe:hedgewars-server
            --builddir=${CABAL_DIST_DIR}
            --installdir=${CMAKE_CURRENT_BINARY_DIR}
            --install-method=copy
            --overwrite-policy=always
             ${CABAL_FLAGS}
             
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "Building hedgewars-server with Cabal..."
    VERBATIM
)

install(PROGRAMS "${SERVER_OUTPUT_PATH}" DESTINATION ${target_binary_install_dir})

