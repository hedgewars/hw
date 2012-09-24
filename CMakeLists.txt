project(hedgewars)


#initialise cmake environment
cmake_minimum_required(VERSION 2.6.0 FATAL_ERROR)
FOREACH(policy CMP0003 CMP0012)
    IF(POLICY ${policy})
        CMAKE_POLICY(SET ${policy} NEW)
    ENDIF()
ENDFOREACH()
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules)


#detect Mercurial revision (if present)
set(version_suffix "-dev") #UNSET THIS VARIABLE AT RELEASE TIME
set(HGCHANGED "")
IF(version_suffix MATCHES "-dev")
    set(HW_DEV true)
    IF (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.hg)
        FIND_PROGRAM(HGCOMMAND hg)
        IF(HGCOMMAND)
            exec_program(${HGCOMMAND}
                     ARGS identify -in ${CMAKE_CURRENT_SOURCE_DIR}
                     OUTPUT_VARIABLE version_suffix
                     )
            STRING(REGEX REPLACE "[^+]" "" HGCHANGED ${version_suffix})
            STRING(REGEX REPLACE "([0-9a-zA-Z]+)(.*) ([0-9]+)(.*)" "\\3-\\1" version_suffix ${version_suffix})
            IF (HGCHANGED)
                MESSAGE(STATUS "Building revision ${version_suffix} (SOURCE CODE MODIFIED)")
            ELSE()
                MESSAGE(STATUS "Building revision ${version_suffix}")
            ENDIF()
            set(version_suffix "-${version_suffix}")
        ENDIF()
    ENDIF()
ELSE()
    set(HW_DEV false)
ENDIF()


#versioning
set(CPACK_PACKAGE_VERSION_MAJOR 0)
set(CPACK_PACKAGE_VERSION_MINOR 9)
set(CPACK_PACKAGE_VERSION_PATCH 18${version_suffix})
set(HEDGEWARS_PROTO_VER 42)
set(HEDGEWARS_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")


#set some safe values
IF(NOT BUILD_ENGINE_LIBRARY)
    SET(BUILD_ENGINE_LIBRARY 0)
ENDIF(NOT BUILD_ENGINE_LIBRARY)
set(target_dir "bin")

#bundle .app setup
if(APPLE OR CROSSAPPLE)
    #paths for creating the bundle
    set(bundle_name Hedgewars.app)
    set(frameworks_dir ${bundle_name}/Contents/Frameworks/)
    set(CMAKE_INSTALL_PREFIX ${bundle_name}/Contents/MacOS/)
    set(DATA_INSTALL_DIR "../Resources/")
    set(target_dir ".")
    set(minimum_macosx_version "10.6")
endif()

if(APPLE)
    set(CMAKE_FIND_FRAMEWORK "FIRST")

    #what system are we building for
    set(minimum_macosx_version $ENV{MACOSX_DEPLOYMENT_TARGET})

    #detect on which system we are: if sw_vers cannot be found for any reason (re)use minimum_macosx_version
    find_program(sw_vers sw_vers)
    if(sw_vers)
        exec_program(${sw_vers} ARGS "-productVersion" OUTPUT_VARIABLE current_macosx_version)
        string(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" current_macosx_version ${current_macosx_version})
        else()
        if(NOT minimum_macosx_version)
            message(FATAL_ERROR "sw_vers not found! Need explicit MACOSX_DEPLOYMENT_TARGET variable set")
        else()
            set(current_macosx_version ${minimum_macosx_version})
        endif()
    endif()

    #if nothing is set, we deploy only for the current system
    if(NOT minimum_macosx_version)
        set(minimum_macosx_version ${current_macosx_version})
    endif()

    #lower systems don't have enough processing power anyways
    if (minimum_macosx_version LESS "10.4")
        message(FATAL_ERROR "Hedgewars is not supported on Mac OS X pre-10.4")
    endif()

    #workaround for http://playcontrol.net/ewing/jibberjabber/big_behind-the-scenes_chang.html#SDL_mixer (Update 2)
    if(current_macosx_version MATCHES "10.4")
        find_package(SDL_mixer REQUIRED)
        set(DYLIB_SMPEG "-dylib_file @loader_path/Frameworks/smpeg.framework/Versions/A/smpeg:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/smpeg.framework/Versions/A/smpeg")
        set(DYLIB_MIKMOD "-dylib_file @loader_path/Frameworks/mikmod.framework/Versions/A/mikmod:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/mikmod.framework/Versions/A/mikmod")
        set(pascal_flags "-k${DYLIB_SMPEG}" "-k${DYLIB_MIKMOD}" ${pascal_flags})
        set(CMAKE_C_FLAGS "${DYLIB_SMPEG}" "${DYLIB_MIKMOD}" ${CMAKE_C_FLAGS})
    endif()

    #CMAKE_OSX_ARCHITECTURES and CMAKE_OSX_SYSROOT need to be set for universal binary and correct linking
    if(NOT CMAKE_OSX_ARCHITECTURES)
        if(current_macosx_version LESS "10.6")
            if(${CMAKE_SYSTEM_PROCESSOR} MATCHES "powerpc*")
                set(CMAKE_OSX_ARCHITECTURES "ppc7400")
            else()
                set(CMAKE_OSX_ARCHITECTURES "i386")
            endif()
        else()
            set(CMAKE_OSX_ARCHITECTURES "x86_64")
        endif()
    endif()

    #CMAKE_OSX_SYSROOT is set at the system version we are supposed to build on
    #we need to provide the correct one when host and target differ
    if(NOT ${minimum_macosx_version} MATCHES ${current_macosx_version})
        if(minimum_macosx_version MATCHES "10.4")
            set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.4u.sdk/")
            set(CMAKE_C_COMPILER "gcc-4.0")
            set(CMAKE_CXX_COMPILER "g++-4.0")
        else()
            string(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" sdk_version ${minimum_macosx_version})
            set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX${sdk_version}.sdk/")
        endif()
    endif()

    #add user framework directory, other paths can be passed via FPFLAGS
    set(pascal_flags "-Ff~/Library/Frameworks" ${pascal_flags})
    #set deployment target
    set(pascal_flags "-k-macosx_version_min" "-k${minimum_macosx_version}" "-XR${CMAKE_OSX_SYSROOT}" ${pascal_flags})

    message(STATUS "Build system: Mac OS X ${current_macosx_version} with GCC:${CMAKE_C_COMPILER}")
    message(STATUS "Target system: Mac OS X ${minimum_macosx_version} for architecture(s):${CMAKE_OSX_ARCHITECTURES}")
endif(APPLE)


#when build type is not specified, assume Debug/Release according to build version information
if (NOT CMAKE_BUILD_TYPE)
    if(HW_DEV)
        set (build_type "DEBUG")
    else()
        set (build_type "RELEASE")
    endif()
    set (CMAKE_BUILD_TYPE ${build_type} CACHE STRING "Choose the type of build, options are: Debug Release." FORCE)
endif (NOT CMAKE_BUILD_TYPE)


#set default flags values for all projects
set(CMAKE_C_FLAGS "-pipe ${CMAKE_C_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE "-w -Os -fomit-frame-pointer ${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_DEBUG "-Wall -O0 -g -DDEBUG ${CMAKE_C_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})
set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})

#parse additional parameters
if(FPFLAGS OR GHFLAGS)
    math(EXPR cmake_version "${CMAKE_MAJOR_VERSION}*10000 + ${CMAKE_MINOR_VERSION}*100 + ${CMAKE_PATCH_VERSION}")
    if(cmake_version LESS "020800")
        message(STATUS "FPFLAGS and GHFLAGS are available only when using CMake >= 2.8")
    else()
        separate_arguments(fpflags_parsed UNIX_COMMAND ${FPFLAGS})
        separate_arguments(ghflags_parsed UNIX_COMMAND ${GHFLAGS})
    endif()
endif()

set(pascal_flags ${fpflags_parsed} "-B" "-FE../bin" "-Cs2000000" "-vewn" "-dDEBUGFILE" ${pascal_flags})
set(haskell_flags "-O2" ${ghflags_parsed} ${haskell_flags})

#get BUILD_TYPE and enable/disable optimisation
if(CMAKE_BUILD_TYPE MATCHES "DEBUG" OR CMAKE_BUILD_TYPE MATCHES "Debug" OR CMAKE_BUILD_TYPE MATCHES "debug")
    message(STATUS "Building Debug")
    set(pascal_flags "-O-" "-g" "-gl" "-gv" "-Ct" ${pascal_flags})
    set(haskell_flags "-Wall" "-debug" "-dcore-lint" "-fno-warn-unused-do-bind" ${haskell_flags})
else()
    message(STATUS "Building Release")
#    set(pascal_flags "-O3" "-OpPENTIUM4" "-CfSSE3" "-Xs" "-Si" ${pascal_flags})
    set(pascal_flags "-Os" "-Ooregvar" "-Xs" "-Si" ${pascal_flags})
    set(haskell_flags "-w" "-fno-warn-unused-do-bind" ${haskell_flags})
endif()


#finish setting paths
if(DEFINED DATA_INSTALL_DIR)
    set(SHAREPATH ${DATA_INSTALL_DIR}/hedgewars/)
else()
    set(SHAREPATH share/hedgewars/)
endif()
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)


#server discovery
if(NOT NOSERVER)
    if(GHC)
        set(ghc_executable ${GHC})
    else()
        find_program(ghc_executable ghc)
    endif()

    if(ghc_executable)
        set(HAVE_NETSERVER true)
        add_subdirectory(gameServer)
    else()
        message(STATUS "No GHC executable found, server will not be built")
        set(HAVE_NETSERVER false)
    endif()
else()
    message(STATUS "Server will not be built per user request")
    set(HAVE_NETSERVER false)
endif()


#lua discovery
find_package(Lua)
if(LUA_FOUND)
    message(STATUS "Lua library is present on your system (${LUA_DEFAULT})")
else()
    message(STATUS "Lua library not found, building bundled dependency")
    add_subdirectory(misc/liblua)
    #linking with liblua.a requires system readline -- this works everywhere, right?
    set(pascal_flags "-k${EXECUTABLE_OUTPUT_PATH}/lib${LUA_LIBRARY}.a" "-k-lreadline" ${pascal_flags})
endif()


#main engine
add_subdirectory(hedgewars)

#Android related build scripts
if(ANDROID)
    #run cmake -DANDROID=1 to enable this
    add_subdirectory(project_files/Android-build)
endif()

#TODO: when ANDROID, BUILD_ENGINE_LIBRARY should be set
if(NOT (BUILD_ENGINE_LIBRARY OR ANDROID))
    add_subdirectory(bin)
    add_subdirectory(misc/quazip)
    add_subdirectory(QTfrontend)
    add_subdirectory(share)
    add_subdirectory(tools)
endif()


# CPack variables
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Hedgewars, a free turn-based strategy")
set(CPACK_PACKAGE_VENDOR "Hedgewars Project")
set(CPACK_PACKAGE_FILE_NAME "hedgewars-${HEDGEWARS_VERSION}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "hedgewars-src-${HEDGEWARS_VERSION}")
set(CPACK_SOURCE_GENERATOR "TBZ2")
set(CPACK_PACKAGE_EXECUTABLES "hedgewars" "hedgewars")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Hedgewars ${HEDGEWARS_VERSION}")

if(WIN32 AND NOT UNIX)
    set(CPACK_NSIS_DISPLAY_NAME "Hedgewars")
    set(CPACK_NSIS_HELP_LINK "http://www.hedgewars.org/")
    set(CPACK_NSIS_URL_INFO_ABOUT "http://www.hedgewars.org/")
    set(CPACK_NSIS_CONTACT "unC0Rr@gmail.com")
    set(CPACK_NSIS_MODIFY_PATH OFF)
    set(CPACK_GENERATOR "ZIP;NSIS")
    set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "hedgewars")
else(WIN32 AND NOT UNIX)
    set(CPACK_STRIP_FILES "bin/hedgewars;bin/hwengine")
endif(WIN32 AND NOT UNIX)

set(CPACK_SOURCE_IGNORE_FILES
    "~"
    "\\\\.hg"
    "\\\\.svn"
    "\\\\.exe$"
    "\\\\.a$"
    "\\\\.dll$"
    "\\\\.xcf$"
    "\\\\.cxx$"
    "\\\\.db$"
    "\\\\.dof$"
    "\\\\.layout$"
    "\\\\.zip$"
    "\\\\.gz$"
    "\\\\.bz2$"
    "\\\\.tmp$"
    "\\\\.core$"
    "\\\\.sh$"
    "\\\\.sifz$"
    "\\\\.svg$"
    "\\\\.svgz$"
    "\\\\.ppu$"
    "\\\\.psd$"
    "\\\\.o$"
    "Makefile"
    "Doxyfile"
    "CMakeFiles"
    "debug"
    "release$"
    "Debug$"
    "Release$"
    "proto\\\\.inc$"
    "hwconsts\\\\.cpp$"
    "playlist\\\\.inc$"
    "CPack"
    "cmake_install\\\\.cmake$"
    "config\\\\.inc$"
    "hwengine\\\\.desktop$"
    "CMakeCache\\\\.txt$"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/libopenalbridge"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/libfreetype"
    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/liblua"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/libtremor"
    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/HedgewarsMobile/"
    "^${CMAKE_CURRENT_SOURCE_DIR}/bin/[a-z]"
    "^${CMAKE_CURRENT_SOURCE_DIR}/tools/templates"
    "^${CMAKE_CURRENT_SOURCE_DIR}/doc"
    "^${CMAKE_CURRENT_SOURCE_DIR}/templates"
    "^${CMAKE_CURRENT_SOURCE_DIR}/Graphics"
    "^${CMAKE_CURRENT_SOURCE_DIR}/realtest"
    "^${CMAKE_CURRENT_SOURCE_DIR}/tmp"
    "^${CMAKE_CURRENT_SOURCE_DIR}/utils"
    "^${CMAKE_CURRENT_SOURCE_DIR}/share/hedgewars/Data/Maps/test"
    "^${CMAKE_CURRENT_SOURCE_DIR}/share/hedgewars/Data/Themes/ethereal"
    "^${CMAKE_CURRENT_SOURCE_DIR}/install_manifest.txt"
    "^${CMAKE_CURRENT_SOURCE_DIR}/CMakeCache.txt"
    "^${CMAKE_CURRENT_SOURCE_DIR}/hedgewars\\\\."
)

include(CPack)

