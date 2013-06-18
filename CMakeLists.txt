project(hedgewars)

#initialise cmake environment
cmake_minimum_required(VERSION 2.6.4)
foreach(hwpolicy CMP0003 CMP0012 CMP0017 CMP0018)
    if(POLICY ${hwpolicy})
        cmake_policy(SET ${hwpolicy} NEW)
    endif()
endforeach()

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake_modules")
include(${CMAKE_MODULE_PATH}/utils.cmake)

#possible cmake configuration
option(NOSERVER "Disable gameServer build (off)]" OFF)
option(NOPNG "Disable screenshoot compression (off)" OFF)
option(NOVIDEOREC "Disable video recording (off)" OFF)

#libraries are built shared unless explicitly added as a static
option(BUILD_SHARED_LIBS "Build libraries as shared modules (on)" ON)
#set this to ON when 2.1.0 becomes more widespread (and only for linux)
option(PHYSFS_SYSTEM "Use system physfs (off)" OFF)

if(WIN32 OR APPLE)
    option(LUA_SYSTEM "Use system lua (off)" OFF)
else()
    option(LUA_SYSTEM "Use system lua (on)" ON)
endif()

option(BUILD_ENGINE_LIBRARY "Enable hwengine library (off)" OFF)
option(ANDROID "Enable Android build (off)" OFF)

if(UNIX AND NOT APPLE)
    option(MINIMAL_FLAGS "Respect system flags as much as possible (off)" OFF)
else()
    option(NOAUTOUPDATE "Disable OS X Sparkle update checking" OFF)
endif()

option(WEBGL "Enable WebGL build (implies NOPASCAL) [default: off]" OFF)
option(NOPASCAL "Compile hwengine as native C [default: off]" ${WEBGL})
option(GL2 "Enable OpenGL 2 rendering [default: off]" OFF)

set(FPFLAGS "" CACHE STRING "Additional Freepascal flags")
set(GHFLAGS "" CACHE STRING "Additional Haskell flags")
if(UNIX AND NOT APPLE)
    set(DATA_INSTALL_DIR "share/hedgewars" CACHE STRING "Resource folder path")
endif()


#versioning
set(CPACK_PACKAGE_VERSION_MAJOR 0)
set(CPACK_PACKAGE_VERSION_MINOR 9)
set(CPACK_PACKAGE_VERSION_PATCH 20)
set(HEDGEWARS_PROTO_VER 46)
set(HEDGEWARS_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
include(${CMAKE_MODULE_PATH}/revinfo.cmake)

message(STATUS "Building ${HEDGEWARS_VERSION}-r${HEDGEWARS_REVISION} (${HEDGEWARS_HASH})")

#general utilities
include(${CMAKE_MODULE_PATH}/utils.cmake)
#platform specific init code
include(${CMAKE_MODULE_PATH}/platform.cmake)
include(${CMAKE_MODULE_PATH}/paths.cmake)


#when build type is not specified, assume Debug/Release according to build version information
if (CMAKE_BUILD_TYPE)
    string (TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
    if ( NOT( (CMAKE_BUILD_TYPE MATCHES "RELEASE") OR (CMAKE_BUILD_TYPE MATCHES "DEBUG") ) )
        set (CMAKE_BUILD_TYPE ${default_build_type} CACHE STRING "Build type (Debug/Release)" FORCE)
        message (STATUS "Unknown build type, using default (${default_build_type})")
    endif ()
else (CMAKE_BUILD_TYPE)
    set (CMAKE_BUILD_TYPE ${default_build_type} CACHE STRING "Build type (Debug/Release)" FORCE)
endif (CMAKE_BUILD_TYPE)


#perform safe check that enable/disable compilation features
include(${CMAKE_MODULE_PATH}/compilerchecks.cmake)

#set default flags values for all projects (unless MINIMAL_FLAGS is true)
if(NOT ${MINIMAL_FLAGS})
    set(CMAKE_C_FLAGS "-pipe ${CMAKE_C_FLAGS}")
    set(CMAKE_C_FLAGS_RELEASE "-w -Os -fomit-frame-pointer ${CMAKE_C_FLAGS_RELEASE}")
    set(CMAKE_C_FLAGS_DEBUG "-Wall -O0 -g ${CMAKE_C_FLAGS_DEBUG}")
    set(CMAKE_CXX_FLAGS "-pipe ${CMAKE_CXX_FLAGS}")
    set(CMAKE_CXX_FLAGS_RELEASE "-w -Os -fomit-frame-pointer ${CMAKE_CXX_FLAGS_RELEASE}")
    set(CMAKE_CXX_FLAGS_DEBUG "-Wall -O0 -g ${CMAKE_CXX_FLAGS_DEBUG}")
else()
    #CMake adds a lot of additional configuration flags, so let's clear them up
    set(CMAKE_C_FLAGS_RELEASE "")
    set(CMAKE_C_FLAGS_DEBUG "-Wall")
    set(CMAKE_CXX_FLAGS_RELEASE "")
    set(CMAKE_CXX_FLAGS_DEBUG "-Wall")
endif()

#parse additional parameters
if(FPFLAGS)
    add_flag_prepend(CMAKE_Pascal_FLAGS ${FPFLAGS})
endif()
if(GHFLAGS)
    if(${allow_parse_args})
        separate_arguments(ghflags_parsed UNIX_COMMAND ${GHFLAGS})
    else()
        message("*** FPFLAGS and GHFLAGS are available only when using CMake >= 2.8 ***")
    endif()
endif()


list(APPEND haskell_flags ${ghflags_parsed} # user flags
                 "-O2"                      # optimise for faster code
                 )

#-vm4079,4080,4081
add_flag_append(CMAKE_Pascal_FLAGS "-Cs2000000")
add_flag_append(CMAKE_Pascal_FLAGS_DEBUG "-O- -gv")
add_flag_append(CMAKE_Pascal_FLAGS_RELEASE "-Os -Xs")

#get BUILD_TYPE and enable/disable optimisation
message(STATUS "Using ${CMAKE_BUILD_TYPE} configuration")
if(CMAKE_BUILD_TYPE MATCHES "DEBUG")
    list(APPEND haskell_flags "-Wall"       # all warnings
                              "-debug"      # debug mode
                              "-dcore-lint" # internal sanity check
                              "-fno-warn-unused-do-bind"
                              )
else()
    list(APPEND haskell_flags "-w" # no warnings
                              )
endif()


#build engine without freepascal
if(${NOPASCAL})
    find_package(Clang)

    if(CLANG_VERSION VERSION_LESS "3.0")
        message(FATAL_ERROR "LLVM/Clang compiler required version is 3.0 but version ${CLANG_VERSION} was found!")
    endif()

    set(CMAKE_C_COMPILER ${CLANG_EXECUTABLE})
    set(CMAKE_CXX_COMPILER ${CLANG_EXECUTABLE})
endif(${NOPASCAL})


#server
if(NOT NOSERVER)
    add_subdirectory(gameServer)
endif()


#lua discovery
if (${LUA_SYSTEM})
    if (NOT LUA_LIBRARY OR NOT LUA_INCLUDE_DIR)
        find_package(Lua)
    endif()

    if (LUA_LIBRARY AND LUA_INCLUDE_DIR)
        set(LUA_FOUND TRUE)
        #use an IMPORTED tharget so that we can just use 'lua' to link
        add_library(lua UNKNOWN IMPORTED)
        set_target_properties(lua PROPERTIES IMPORTED_LOCATION ${LUA_LIBRARY})
    else()
        message(FATAL_ERROR "Missing Lua! Rerun cmake with -DLUA_SYSTEM=off to build the internal version")
    endif()
else()
    if (NOT LUA_LIBRARY OR NOT LUA_INCLUDE_DIR)
        message(STATUS "LUA will be provided by the bundled sources")
    endif()
    set(lua_output_name "hwlua")
    add_subdirectory(misc/liblua)
endif()


#physfs discovery
if (${PHYSFS_SYSTEM})
    if (NOT PHYSFS_LIBRARY OR NOT PHYSFS_INCLUDE_DIR)
        find_package(PhysFS)
    endif()

    find_file(physfs_h physfs.h ${PHYSFS_INCLUDE_DIR})
    if(physfs_h)
        file(STRINGS ${physfs_h} physfs_majorversion REGEX "PHYSFS_VER_MAJOR[\t' ']+[0-9]+")
        file(STRINGS ${physfs_h} physfs_minorversion REGEX "PHYSFS_VER_MINOR[\t' ']+[0-9]+")
        file(STRINGS ${physfs_h} physfs_patchversion REGEX "PHYSFS_VER_PATCH[\t' ']+[0-9]+")
        string(REGEX MATCH "([0-9]+)" physfs_majorversion "${physfs_majorversion}")
        string(REGEX MATCH "([0-9]+)" physfs_minorversion "${physfs_minorversion}")
        string(REGEX MATCH "([0-9]+)" physfs_patchversion "${physfs_patchversion}")
        set(physfs_detected_ver "${physfs_majorversion}.${physfs_minorversion}.${physfs_patchversion}")

        if (physfs_detected_ver VERSION_LESS "2.1.0")
            message(FATAL_ERROR "PhysFS version is too old (dected ${physfs_detected_ver}, required 2.1.0)")
            set(physfs_too_old true)
        endif()
    endif()

    if (NOT PHYSFS_LIBRARY OR NOT PHYSFS_INCLUDE_DIR)
        message(FATAL_ERROR "Missing PhysFS! Rerun cmake with -DPHYSFS_SYSTEM=off to build the internal version")
    else()
        #use an IMPORTED tharget so that we can just use 'physfs' to link
        add_library(physfs UNKNOWN IMPORTED)
        set_target_properties(physfs PROPERTIES IMPORTED_LOCATION ${PHYSFS_LIBRARY})
    endif()
else()
    if (NOT PHYSFS_LIBRARY OR NOT PHYSFS_INCLUDE_DIR)
        message(STATUS "PhysFS will be provided by the bundled sources")
    endif()
    set(physfs_output_name "hwphysfs")
    add_subdirectory(misc/libphysfs)
endif()

find_package_or_disable_msg(FFMPEG NOVIDEOREC "Video recording will not be built")

#physfs helper library
add_subdirectory(misc/libphyslayer)

if(NOT BUILD_ENGINE_LIBRARY AND APPLE)
    add_subdirectory(hedgewars/sdlmain)
endif()

#TODO: nowadays this could be merged inside hedgewars/CMakeLists.txt
if(NOPASCAL)
    #pascal to c converter
    add_subdirectory(tools/pas2c)
    add_subdirectory(project_files/hwc)
else()
    #main pascal engine
    add_subdirectory(hedgewars)
endif()

if(WEBGL)
    #WEBGL deps
else(WEBGL)
    #Android related build scripts
    #TODO: when ANDROID, BUILD_ENGINE_LIBRARY should be set
    if(ANDROID)
        add_subdirectory(project_files/Android-build)
    else(ANDROID)
        add_subdirectory(bin)
        add_subdirectory(QTfrontend)
        add_subdirectory(share)
        add_subdirectory(tools)
    endif(ANDROID)
endif(WEBGL)

include(${CMAKE_MODULE_PATH}/cpackvars.cmake)

