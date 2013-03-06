project(hedgewars)

#initialise cmake environment
cmake_minimum_required(VERSION 2.6.0)
if(CMAKE_VERSION VERSION_LESS "2.8")
    set(WARNING "WARNING: ")
    set(allow_parse_args FALSE)
else()
    set(WARNING WARNING)
    set(allow_parse_args TRUE)
endif()
foreach(hwpolicy CMP0003 CMP0012 CMP0017)
    if(POLICY ${hwpolicy})
        cmake_policy(SET ${hwpolicy} NEW)
    endif()
endforeach()

#use available modules, fallback to ours if not present (CMP0017 helps)
set(CMAKE_MODULE_PATH "${CMAKE_ROOT}/Modules" "${CMAKE_SOURCE_DIR}/cmake_modules")


#possible cmake configuration
option(NOSERVER "Disable gameServer build [default: auto]" OFF)
option(NOPNG "Disable screenshoot compression [default: auto]" OFF)
option(NOVIDEOREC "Disable video recording [default: off]" OFF)

#set this to ON when 2.1.0 becomes more widespread (and only for linux)
option(SYSTEM_PHYSFS "Use system physfs [default:off]" OFF)

option(BUILD_ENGINE_LIBRARY "Enable hwengine library [default: off]" OFF)
option(ANDROID "Enable Android build [default: off]" OFF)
option(MINIMAL_FLAGS "Respect system flags as much as possible [default: off]" OFF)
if(APPLE)
    option(NOAUTOUPDATE "Disable OS X Sparkle update checking" OFF)
endif()

set(FPFLAGS "" CACHE STRING "Additional Freepascal flags")
set(GHFLAGS "" CACHE STRING "Additional Haskell flags")
if(UNIX AND NOT APPLE)
    set(DATA_INSTALL_DIR "share/hedgewars" CACHE STRING "Resource folder path")
endif()


#detect Mercurial revision and init rev/hash information
find_program(HGCOMMAND hg)
if(HGCOMMAND AND (EXISTS ${CMAKE_SOURCE_DIR}/.hg))
    execute_process(COMMAND ${HGCOMMAND} identify -in
                    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                    OUTPUT_VARIABLE internal_version
                    ERROR_QUIET
                )
    #check local repo status
    string(REGEX REPLACE "[^+]" "" HGCHANGED ${internal_version})
    string(REGEX REPLACE "[0-9a-zA-Z]+(.*) ([0-9]+)(.*)" "\\2" HEDGEWARS_REVISION ${internal_version})
    string(REGEX REPLACE "([0-9a-zA-Z]+)(.*) [0-9]+(.*)" "\\1" HEDGEWARS_HASH ${internal_version})

    if(HGCHANGED)
        message(${WARNING} "You have uncommitted changes in your repository!")
    endif()
    #let's assume that if you have hg you might be interested in debugging
    set(default_build_type "DEBUG")
    #write down hash and rev for easy picking should hg be missing
    file(WRITE "${CMAKE_SOURCE_DIR}/share/version_info.txt" "Hedgewars versioning information, do not modify\nrev ${HEDGEWARS_REVISION}\nhash ${HEDGEWARS_HASH}\n")
else()
    set(default_build_type "RELEASE")
    # when compiling outside rev control, fetch revision and hash information from version_info.txt
    find_file(version_info version_info.txt PATH ${CMAKE_SOURCE_DIR}/share)
    if(version_info)
        file(STRINGS ${version_info} internal_version REGEX "rev")
        string(REGEX REPLACE "rev ([0-9]*)" "\\1" HEDGEWARS_REVISION ${internal_version})
        file(STRINGS ${version_info} internal_version REGEX "hash")
        string(REGEX REPLACE "hash ([a-zA-Z0-9]*)" "\\1" HEDGEWARS_HASH ${internal_version})
    else()
        message(${WARNING} "${CMAKE_SOURCE_DIR}/share/version_info.txt not found, revision information "
                           "will be incorrect!!! Contact your source provider to fix this!")
        set(HEDGEWARS_REVISION "0000")
        set(HEDGEWARS_HASH "unknown")
    endif()
endif()


#versioning
set(CPACK_PACKAGE_VERSION_MAJOR 0)
set(CPACK_PACKAGE_VERSION_MINOR 9)
set(CPACK_PACKAGE_VERSION_PATCH 19)
set(HEDGEWARS_PROTO_VER 44)
set(HEDGEWARS_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

message(STATUS "Building ${HEDGEWARS_VERSION}-r${HEDGEWARS_REVISION} (${HEDGEWARS_HASH})")


#where to build libs and bins
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

#resource paths
if(UNIX AND NOT APPLE)
    set(target_binary_install_dir "bin")
    set(target_library_install_dir "lib")

    string(SUBSTRING "${DATA_INSTALL_DIR}" 0 1 sharepath_start)
    if (NOT (${sharepath_start} MATCHES "/"))
        set(HEDGEWARS_DATADIR "${CMAKE_INSTALL_PREFIX}/${DATA_INSTALL_DIR}/")
    else()
        set(HEDGEWARS_DATADIR "${DATA_INSTALL_DIR}/")
    endif()
    set(HEDGEWARS_FULL_DATADIR "${HEDGEWARS_DATADIR}")
else()
    set(target_binary_install_dir "./")

    if(APPLE)
        set(target_library_install_dir "../Frameworks/")
        set(CMAKE_INSTALL_PREFIX "Hedgewars.app/Contents/MacOS/")
        set(HEDGEWARS_DATADIR "../Resources/")
        set(HEDGEWARS_FULL_DATADIR "/Applications/${CMAKE_INSTALL_PREFIX}/${HEDGEWARS_DATADIR}")
    elseif(WIN32)
        set(target_library_install_dir "./")
        set(HEDGEWARS_DATADIR "./")
        set(HEDGEWARS_FULL_DATADIR "${CMAKE_INSTALL_PREFIX}/")
        set(CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/misc/winutils/")
        link_directories("${EXECUTABLE_OUTPUT_PATH}" "${CMAKE_SOURCE_DIR}/misc/winutils/bin")
    endif()
endif()


if(APPLE)
    set(CMAKE_FIND_FRAMEWORK "FIRST")

    #what system are we building for
    set(minimum_macosx_version $ENV{MACOSX_DEPLOYMENT_TARGET})

    #detect on which system we are: if sw_vers cannot be found for any reason (re)use minimum_macosx_version
    find_program(sw_vers sw_vers)
    if(sw_vers)
        execute_process(COMMAND ${sw_vers} "-productVersion"
                        OUTPUT_VARIABLE current_macosx_version
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        string(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" current_macosx_version ${current_macosx_version})
    else()
        if(NOT minimum_macosx_version)
            message(FATAL_ERROR "sw_vers not found! Need explicit MACOSX_DEPLOYMENT_TARGET variable set")
        else()
            message(${WARNING} "sw_vers not found! Fallback to MACOSX_DEPLOYMENT_TARGET variable")
            set(current_macosx_version ${minimum_macosx_version})
        endif()
    endif()

    #if nothing is set, we deploy only for the current system
    if(NOT minimum_macosx_version)
        set(minimum_macosx_version ${current_macosx_version})
    endif()

    #lower systems don't have enough processing power anyway
    if (minimum_macosx_version VERSION_LESS "10.4")
        message(FATAL_ERROR "Hedgewars is not supported on Mac OS X pre-10.4")
    endif()

    #workaround for http://playcontrol.net/ewing/jibberjabber/big_behind-the-scenes_chang.html#SDL_mixer (Update 2)
    if(current_macosx_version VERSION_EQUAL "10.4")
        find_package(SDL_mixer REQUIRED)
        set(DYLIB_SMPEG "-dylib_file @loader_path/Frameworks/smpeg.framework/Versions/A/smpeg:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/smpeg.framework/Versions/A/smpeg")
        set(DYLIB_MIKMOD "-dylib_file @loader_path/Frameworks/mikmod.framework/Versions/A/mikmod:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/mikmod.framework/Versions/A/mikmod")
        set(CMAKE_C_FLAGS "${DYLIB_SMPEG} ${DYLIB_MIKMOD}")
        list(APPEND pascal_flags "-k${DYLIB_SMPEG}" "-k${DYLIB_MIKMOD}")
    endif()

    #CMAKE_OSX_ARCHITECTURES and CMAKE_OSX_SYSROOT need to be set for universal binary and correct linking
    if(NOT CMAKE_OSX_ARCHITECTURES)
        if(current_macosx_version VERSION_LESS "10.6")
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
    if(NOT ${minimum_macosx_version} VERSION_EQUAL ${current_macosx_version})
        if(minimum_macosx_version VERSION_EQUAL "10.4")
            set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.4u.sdk/")
            set(CMAKE_C_COMPILER "gcc-4.0")
            set(CMAKE_CXX_COMPILER "g++-4.0")
        else()
            string(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" sdk_version ${minimum_macosx_version})
            set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX${sdk_version}.sdk/")
        endif()
    endif()

    #add user framework directory, other paths can be passed via FPFLAGS
    list(APPEND pascal_flags "-Ff~/Library/Frameworks")
    #set deployment target
    list(APPEND pascal_flags "-k-macosx_version_min" "-k${minimum_macosx_version}" "-XR${CMAKE_OSX_SYSROOT}")
endif(APPLE)


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


#set default flags values for all projects (unless MINIMAL_FLAGS is true)
if(NOT ${MINIMAL_FLAGS})
    set(CMAKE_C_FLAGS "-pipe ${CMAKE_C_FLAGS}")
    set(CMAKE_C_FLAGS_RELEASE "-w -Os -fomit-frame-pointer ${CMAKE_C_FLAGS_RELEASE}")
    set(CMAKE_C_FLAGS_DEBUG "-Wall -O0 -g -DDEBUG ${CMAKE_C_FLAGS_DEBUG}")
    set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})
    set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
    set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})
else()
    #CMake adds a lot of additional configuration flags, so let's clear them up
    set(CMAKE_C_FLAGS_RELEASE "")
    set(CMAKE_C_FLAGS_DEBUG "-Wall -DDEBUG")
    set(CMAKE_CXX_FLAGS_RELEASE "")
    set(CMAKE_CXX_FLAGS_DEBUG "-Wall -DDEBUG")
endif()

#TODO: find out why we need this...
include(CheckCSourceCompiles)
set(CMAKE_REQUIRED_FLAG "-Wl,-z -Wl,noexecstack")
check_c_source_compiles("int main(void) { return 0; }" HAVE_NOEXECSTACK)
if(HAVE_NOEXECSTACK)
    list(APPEND pascal_flags "-k-z" "-knoexecstack")
    if(NOT ${MINIMAL_FLAGS})
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CMAKE_REQUIRED_FLAG}")
    endif()
endif()
unset(CMAKE_REQUIRED_FLAG)

#parse additional parameters
if(FPFLAGS OR GHFLAGS)
    if(${allow_parse_args})
        message(${WARNING} "FPFLAGS and GHFLAGS are available only when using CMake >= 2.8")
    else()
        separate_arguments(fpflags_parsed UNIX_COMMAND ${FPFLAGS})
        separate_arguments(ghflags_parsed UNIX_COMMAND ${GHFLAGS})
    endif()
endif()

list(APPEND pascal_flags ${fpflags_parsed}        # user flags
                 "-vm4079,4080,4081"              # fpc output format
                 "-B"                             # compile all units
                 "-FE${PROJECT_BINARY_DIR}/bin"   # fpc output directory
                 "-Fl${PROJECT_BINARY_DIR}/bin"   # fpc linking directory (win/unix)
                 "-k-L${PROJECT_BINARY_DIR}/bin"  # ld linking directory (unix/osx)
                 "-Cs2000000"                     # stack size
                 "-vewnq"                         # fpc output verbosity
                 "-dDEBUGFILE"                    # macro for engine output
                 )
list(APPEND haskell_flags ${ghflags_parsed}       # user flags
                 "-O2"                            # optimise for faster code
                 )


#get BUILD_TYPE and enable/disable optimisation
message(STATUS "Using ${CMAKE_BUILD_TYPE} configuration")
if(CMAKE_BUILD_TYPE MATCHES "DEBUG")
    list(APPEND pascal_flags "-O-"                # disable all optimisations
                             "-g"                 # enable debug symbols
                             "-gl"                # add line info to bt
                             "-gv"                # allow valgrind
                             )
    list(APPEND haskell_flags "-Wall"             # all warnings
                              "-debug"            # debug mode
                              "-dcore-lint"       # internal sanity check
                              )
else()
    list(APPEND pascal_flags "-Os"                # optimise for size
                             "-Xs"                # strip binary
                             "-Si"                # turn on inlining
                             )
    list(APPEND haskell_flags "-w"                # no warnings
                              )
endif()



#server discovery
if(NOT NOSERVER)
    if(GHC)
        set(ghc_executable ${GHC})
    else()
        find_program(ghc_executable ghc)
    endif()

    if(ghc_executable)
        add_subdirectory(gameServer)
        message(STATUS "Found GHC: ${ghc_executable}")
    else()
        message(${WARNING} "Could NOT find GHC, server will not be built")
        set(HAVE_NETSERVER false)
    endif()
else()
    message(STATUS "Server will not be built per user request")
    set(HAVE_NETSERVER false)
endif()


#lua discovery
find_package(Lua)
if(LUA_FOUND)
    message(STATUS "Found LUA: ${LUA_DEFAULT}")
else()
    message(STATUS "LUA will be provided by the bundled sources")
    add_subdirectory(misc/liblua)
    #linking with liblua.a requires system readline
    list(APPEND pascal_flags "-k${EXECUTABLE_OUTPUT_PATH}/lib${LUA_LIBRARY}.a" "-k-lreadline")
endif()


#physfs discovery
if (${SYSTEM_PHYSFS})
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
    endif()
else()
    message(STATUS "PhysFS will be provided by the bundled sources")
    set(physfs_output_name "hw_physfs")
    add_subdirectory(misc/libphysfs)
    #-XLA is a beta fpc flag that renames libraries before passing them to the linker
    #we also have to pass PHYSFS_INTERNAL to satisfy windows runtime requirements
    #(should be harmless on other platforms)
    list(APPEND pascal_flags "-XLAphysfs=${physfs_output_name}" "-dPHYSFS_INTERNAL")
endif()

if(NOT ${NOVIDEOREC})
    find_package(FFMPEG)
    if(NOT ${FFMPEG_FOUND})
        message(FATAL_ERROR "Missing FFMPEG/Libav! Rerun cmake with -DNOVIDEOREC=on to disable video recording")
    endif()
else()
    set(FFMPEG_FOUND false)
endif()

#
add_subdirectory(misc/libphyslayer)

#main engine
add_subdirectory(hedgewars)

#Android related build scripts
if(ANDROID)
    #run cmake -DANDROID=1 to enable this
    add_subdirectory(project_files/Android-build)
endif()

#TODO: when ANDROID, BUILD_ENGINE_LIBRARY should be set
if(NOT ANDROID)
    add_subdirectory(bin)
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
    set(CPACK_NSIS_EXECUTABLES_DIRECTORY "${target_binary_install_dir}")
    set(CPACK_GENERATOR "ZIP;NSIS")
    set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "hedgewars")
else(WIN32 AND NOT UNIX)
    set(CPACK_STRIP_FILES "bin/hedgewars;bin/hwengine")
endif(WIN32 AND NOT UNIX)

set(CPACK_SOURCE_IGNORE_FILES
    #temporary files
    "~"
    ".swp"
    #version control
    "\\\\.hg"
    #output binary/library
    "\\\\.exe$"
    "\\\\.a$"
    "\\\\.so$"
    "\\\\.dylib$"
    "\\\\.dll$"
    "\\\\.ppu$"
    "\\\\.o$"
    "\\\\.cxx$"
    #graphics
    "\\\\.xcf$"
    "\\\\.svg$"
    "\\\\.svgz$"
    "\\\\.psd$"
    "\\\\.sifz$"
    #misc
    "\\\\.core$"
    "\\\\.sh$"
    "\\\\.orig$"
    "\\\\.layout$"
    "\\\\.db$"
    "\\\\.dof$"
    #archives
    "\\\\.zip$"
    "\\\\.gz$"
    "\\\\.bz2$"
    "\\\\.tmp$"
    #cmake-configured files
    "hwconsts\\\\.cpp$"
    "config\\\\.inc$"
    "hwengine\\\\.desktop$"
    "Info\\\\.plist$"
    #other cmake generated files
    "Makefile"
    "Doxyfile"
    "CMakeFiles"
    "[dD]ebug$"
    "[rR]elease$"
    "CPack"
    "cmake_install\\\\.cmake$"
    "CMakeCache\\\\.txt$"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/libtremor"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/libfreetype"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/liblua"
    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/libopenalbridge"
    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/frontlib"
    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/promotional_art"
    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/cmdlineClient"
    "^${CMAKE_CURRENT_SOURCE_DIR}/tools/templates"
    "^${CMAKE_CURRENT_SOURCE_DIR}/bin/checkstack*"
    "^${CMAKE_CURRENT_SOURCE_DIR}/doc"
    "^${CMAKE_CURRENT_SOURCE_DIR}/templates"
    "^${CMAKE_CURRENT_SOURCE_DIR}/tmp"
    "^${CMAKE_CURRENT_SOURCE_DIR}/utils"
    "^${CMAKE_CURRENT_SOURCE_DIR}/share/hedgewars/Data/Maps/test"
    "^${CMAKE_CURRENT_SOURCE_DIR}/install_manifest.txt"
    "^${CMAKE_CURRENT_SOURCE_DIR}/CMakeCache.txt"
    "^${CMAKE_CURRENT_SOURCE_DIR}/hedgewars\\\\."
)

include(CPack)

