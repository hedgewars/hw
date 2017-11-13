project(hedgewars)


#initialise cmake environment
cmake_minimum_required(VERSION 2.6.4)
foreach(hwpolicy CMP0003 CMP0012 CMP0017 CMP0018)
    if(POLICY ${hwpolicy})
        cmake_policy(SET ${hwpolicy} NEW)
    endif()
endforeach()

foreach(hwpolicy CMP0026)
    if(POLICY ${hwpolicy})
        cmake_policy(SET ${hwpolicy} OLD)
    endif()
endforeach()

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake_modules")
include(${CMAKE_MODULE_PATH}/utils.cmake)

#possible cmake configuration
option(NOSERVER "Disable gameServer build (off)" OFF)
option(NOPNG "Disable screenshoot compression (off)" OFF)
option(NOVIDEOREC "Disable video recording (off)" OFF)

#libraries are built shared unless explicitly added as a static
option(BUILD_SHARED_LIBS "Build libraries as shared modules (on)" ON)

if(WIN32 OR APPLE)
    option(PHYSFS_SYSTEM "Use system physfs (off)" OFF)
    option(LUA_SYSTEM "Use system lua (off)" OFF)
else()
    option(PHYSFS_SYSTEM "Use system physfs (on)" ON)
    option(LUA_SYSTEM "Use system lua (on)" ON)
endif()

option(BUILD_ENGINE_LIBRARY "Enable hwengine library (off)" OFF)
option(ANDROID "Enable Android build (off)" OFF)

option(MINIMAL_FLAGS "Respect system flags as much as possible (off)" OFF)
option(NOAUTOUPDATE "Disable OS X Sparkle update checking (off)" OFF)
option(SKIPBUNDLE "Do not create relocate bundle (off)" OFF)

option(BUILD_ENGINE_C "Compile hwengine as native C (off)" OFF)
option(BUILD_ENGINE_JS "Compile hwengine as javascript (off)" OFF)
option(GL2 "Enable OpenGL 2 rendering !!!EXPERIMENTAL - DO NOT USE!!! [default: off)" OFF)

set(GHFLAGS "" CACHE STRING "Additional Haskell flags")
if(UNIX AND NOT APPLE)
    set(DATA_INSTALL_DIR "share/hedgewars" CACHE STRING "Resource folder path")
endif()

option(NOVERSIONINFOUPDATE "Disable update of version_info.txt. To be used if source is in a git/repo that is NOT the hedgewars repo" OFF)


if(BUILD_ENGINE_JS)
    if(NOT CMAKE_TOOLCHAIN_FILE)
        message(FATAL_ERROR "Missing emscripten toolchain file\nClean your cache and rerun cmake with -DCMAKE_TOOLCHAIN_FILE=${CMAKE_SOURCE_DIR}/cmake_modules/Platform/Emscripten.cmake")
    endif()

    set(BUILD_ENGINE_C ON CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(BUILD_ENGINE_LIBRARY ON CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(NOAUTOUPDATE ON CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(PHYSFS_SYSTEM OFF CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(LUA_SYSTEM OFF CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(NOVIDEOREC ON CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(NOSERVER ON CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(GL2 ON CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE STRING "Required for BUILD_ENGINE_JS" FORCE)

    set(target_binary_install_dir "bin" CACHE PATH "install dest for binaries")
    set(target_library_install_dir "lib" CACHE PATH "install dest for libs")
endif()

#system paths for finding required fonts (see share/hedgewars/Data/fonts)
#subdirectories will NOT be searched.
#all fonts that can't be found will be bundled with hedgewars
set(FONTS_DIRS "" CACHE STRING "Additional paths to folders where required fonts can be found ( ; is separator)")

#versioning
set(CPACK_PACKAGE_VERSION_MAJOR 0)
set(CPACK_PACKAGE_VERSION_MINOR 9)
set(CPACK_PACKAGE_VERSION_PATCH 23)
set(HEDGEWARS_PROTO_VER 53)
set(HEDGEWARS_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
include(${CMAKE_MODULE_PATH}/revinfo.cmake)

message(STATUS "Building ${HEDGEWARS_VERSION}-r${HEDGEWARS_REVISION} (${HEDGEWARS_HASH})")

#io library paths
include(${CMAKE_MODULE_PATH}/paths.cmake)
#general utilities
include(${CMAKE_MODULE_PATH}/utils.cmake)
#platform specific init code
include(${CMAKE_MODULE_PATH}/platform.cmake)


#when build type is not specified, assume Debug/Release according to build version information
if(CMAKE_BUILD_TYPE)
    string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE)
    if(NOT((CMAKE_BUILD_TYPE MATCHES "RELEASE") OR
           (CMAKE_BUILD_TYPE MATCHES "DEBUG") OR
           (CMAKE_BUILD_TYPE MATCHES "RELWITHDEBINFO")))
        set(CMAKE_BUILD_TYPE ${default_build_type} CACHE STRING "Build type (Debug/Release/RelWithDebInfo)" FORCE)
        message(STATUS "Unknown build type ${CMAKE_BUILD_TYPE}, using default (${default_build_type})")
    endif()
else(CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE ${default_build_type} CACHE STRING "Build type (Debug/Release/RelWithDebInfo)" FORCE)
endif(CMAKE_BUILD_TYPE)


#perform safe check that enable/disable compilation features
#skip when crosscompiling to javascript
if(NOT BUILD_ENGINE_JS)
    include(${CMAKE_MODULE_PATH}/compilerchecks.cmake)
endif()

#set default compiler flags
add_flag_append(CMAKE_C_FLAGS "-Wall -pipe")
add_flag_append(CMAKE_C_FLAGS_RELEASE "-O2")
add_flag_append(CMAKE_C_FLAGS_DEBUG "-Wextra -O0")
add_flag_append(CMAKE_CXX_FLAGS "-Wall -pipe")
add_flag_append(CMAKE_CXX_FLAGS_RELEASE "-O2")
add_flag_append(CMAKE_CXX_FLAGS_DEBUG "-Wextra -O0")

#CMake adds a lot of additional configuration flags, so let's clear them up
if(MINIMAL_FLAGS)
    unset(CMAKE_C_FLAGS_RELEASE)
    unset(CMAKE_C_FLAGS_DEBUG)
    unset(CMAKE_CXX_FLAGS_RELEASE)
    unset(CMAKE_CXX_FLAGS_DEBUG)
endif()


#parse additional parameters
if(GHFLAGS)
    if(${CMAKE_VERSION} VERSION_GREATER 2.6)
        separate_arguments(ghflags_parsed UNIX_COMMAND ${GHFLAGS})
    else()
        message("*** GHFLAGS are available only when using CMake >= 2.8 ***")
    endif()
endif()


#get BUILD_TYPE and enable/disable optimisation
message(STATUS "Using ${CMAKE_BUILD_TYPE} configuration")
if(CMAKE_BUILD_TYPE MATCHES "DEBUG")
    list(APPEND haskell_flags "-Wall"       # all warnings
                              "-debug"      # debug mode
                              "-fno-warn-unused-do-bind"
                              "-O0"
                              )
else()
    list(APPEND haskell_flags "-w" # no warnings
                              "-O2"
                              )
endif()


#build engine without freepascal
if(BUILD_ENGINE_C AND NOT BUILD_ENGINE_JS)
    find_package(Clang REQUIRED)

    if(${CLANG_VERSION} VERSION_LESS "3.0")
        message(FATAL_ERROR "LLVM/Clang compiler required version is 3.0 but version ${CLANG_VERSION} was found!")
    endif()

    set(CMAKE_C_COMPILER ${CLANG_EXECUTABLE})
    set(CMAKE_CXX_COMPILER ${CLANG_EXECUTABLE})
endif()


#server
if(NOT NOSERVER)
    add_subdirectory(gameServer)
endif()


#lua discovery
if(LUA_SYSTEM)
    if(NOT LUA_LIBRARY OR NOT LUA_INCLUDE_DIR)
        find_package(Lua)
    endif()

    if(LUA_LIBRARY AND LUA_INCLUDE_DIR)
        #use an IMPORTED tharget so that we can just use 'lua' to link
        add_library(lua UNKNOWN IMPORTED)
        set_target_properties(lua PROPERTIES IMPORTED_LOCATION ${LUA_LIBRARY})
    else()
        message(FATAL_ERROR "Missing Lua! Rerun cmake with -DLUA_SYSTEM=off to build the internal version")
    endif()
else()
    if(NOT LUA_LIBRARY OR NOT LUA_INCLUDE_DIR)
        message(STATUS "LUA will be provided by the bundled sources")
    endif()
    set(lua_output_name "hwlua")
    add_subdirectory(misc/liblua)
endif()


#physfs discovery
if(PHYSFS_SYSTEM)
    if(NOT PHYSFS_LIBRARY OR NOT PHYSFS_INCLUDE_DIR)
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

        if(${physfs_detected_ver} VERSION_LESS 2.0.0)
            message(FATAL_ERROR "PhysFS version is too old (detected ${physfs_detected_ver}, required 2.0.0)\n"
                                "Perform an update or rerun cmake with -DPHYSFS_SYSTEM=off to build the internal version")
        endif()
    endif()

    if(PHYSFS_LIBRARY AND PHYSFS_INCLUDE_DIR)
        #use an IMPORTED tharget so that we can just use 'physfs' to link
        add_library(physfs UNKNOWN IMPORTED)
        set_target_properties(physfs PROPERTIES IMPORTED_LOCATION ${PHYSFS_LIBRARY})
    else()
        message(FATAL_ERROR "Missing PhysFS! Rerun cmake with -DPHYSFS_SYSTEM=off to build the internal version")
    endif()
else()
    if(NOT PHYSFS_LIBRARY OR NOT PHYSFS_INCLUDE_DIR)
        message(STATUS "PhysFS will be provided by the bundled sources")
    endif()
    set(physfs_output_name "hwphysfs")
    add_subdirectory(misc/libphysfs)
endif()

find_package_or_disable_msg(LIBAV NOVIDEOREC "Video recording will not be built")

#physfs helper library
add_subdirectory(misc/libphyslayer)

#maybe this could be merged inside hedgewars/CMakeLists.txt
if(BUILD_ENGINE_C)
    #pascal to c converter
    add_subdirectory(tools/pas2c)
    add_subdirectory(project_files/hwc)
else()
    #main pascal engine
    add_subdirectory(hedgewars)
endif()

#Android related build scripts
#TODO: when ANDROID, BUILD_ENGINE_LIBRARY should be set
if(ANDROID)
    add_subdirectory(project_files/Android-build)
else(ANDROID)
    #skip frontend for javascript
    if(NOT BUILD_ENGINE_JS)
        add_subdirectory(QTfrontend)
        add_subdirectory(share)
    endif()

    add_subdirectory(bin)
    add_subdirectory(tools)
endif(ANDROID)

include(${CMAKE_MODULE_PATH}/cpackvars.cmake)

enable_testing()

add_custom_target(test_normal  COMMAND ${CMAKE_CTEST_COMMAND} -E '^todo/' --timeout 300 --schedule-random)
add_custom_target(test_verbose COMMAND ${CMAKE_CTEST_COMMAND} -E '^todo/' --timeout 300 --schedule-random -V)

set(LUATESTS_DIR "${CMAKE_SOURCE_DIR}/tests/lua")
set(TESTSDATA_DIR "${CMAKE_SOURCE_DIR}/share/hedgewars/Data")

# set set this to "" if you want to see what's going on
# TODO: engine should do this implicitly when running tests,
# unless some env var like HWENGINE_SHOWTESTS is set or something
set(STATSONLYFLAG "--stats-only")

# add all lua tests
file(GLOB_RECURSE luatests RELATIVE "${LUATESTS_DIR}" "${LUATESTS_DIR}/*.lua")
foreach(luatest ${luatests})
    add_test("${luatest}" "bin/hwengine" "--prefix" "${TESTSDATA_DIR}" "--nosound" "--nomusic" "${STATSONLYFLAG}" "--lua-test" "${LUATESTS_DIR}/${luatest}")
endforeach(luatest)

