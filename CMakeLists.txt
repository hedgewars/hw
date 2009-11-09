project(hedgewars)

cmake_minimum_required(VERSION 2.6.0 FATAL_ERROR)

if(COMMAND cmake_policy)
	cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules)

set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "9")
set(CPACK_PACKAGE_VERSION_PATCH "13-dev")

set(build_type "standard")

if(APPLE)
	set(CMAKE_FIND_FRAMEWORK "FIRST")
	
	#paths for creating the bundle
	set(bundle_name Hedgewars.app)
	set(CMAKE_INSTALL_PREFIX ${bundle_name}/Contents/MacOS/) 
	set(DATA_INSTALL_DIR "../Resources/")
	set(target_dir ".")
	
	#build architecture / os version
	set(minimum_os $ENV{MACOSX_DEPLOYMENT_TARGET})
	if(minimum_os MATCHES "10.4")
		message(STATUS "Target: Mac OS X 10.4 i386")	
		set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.4u.sdk/")
		set(CMAKE_OSX_ARCHITECTURES "i386")
		set(build_type "standard")
	endif()
	if(minimum_os MATCHES "10.5")
		message(STATUS "Target: Mac OS X 10.5 i386/ppc")
		set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.5.sdk/")
		set(CMAKE_OSX_ARCHITECTURES "i386;ppc7400")
		set(build_type "universal")
	endif()
	if(minimum_os MATCHES "10.6")
		message(STATUS "Target: Mac OS X 10.6 i386/ppc/x86_64")
		set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.6.sdk/")
		set(CMAKE_OSX_ARCHITECTURES "x86_64;i386;ppc7400")
		set(build_type "universal64")
	endif()
	if(NOT minimum_os)
	#use the default sysroot with default archs	
		EXEC_PROGRAM(sw_vers OUTPUT_VARIABLE MACOSX_VERSION)
		string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" MACOSX_VERSION "${MACOSX_VERSION}")
		STRING(REGEX REPLACE "[0-9][0-9].([0-9]+).[0-9]" "\\1" MACOSX_VERSION ${MACOSX_VERSION})
		set(minimum_os "10.${MACOSX_VERSION}")
	endif()
else(APPLE)
	set(target_dir "bin")
endif(APPLE)


#this snippet sets "Release" mode by default
if (NOT CMAKE_BUILD_TYPE)
	set (CMAKE_BUILD_TYPE RELEASE CACHE STRING "Choose the type of build, options are: None Debug Release." FORCE)
endif (NOT CMAKE_BUILD_TYPE)

if(CMAKE_BUILD_TYPE MATCHES RELEASE OR CMAKE_BUILD_TYPE MATCHES "Release")
	message(STATUS "Building Release")	
	set(Optz true)
else()
	message(STATUS "Building Debug")	
	set(CMAKE_VERBOSE_MAKEFILE true)
	set(Optz false)
endif()


#set default flags values for all the project
set(CMAKE_C_FLAGS "-Wall -pipe")
set(CMAKE_C_FLAGS_RELEASE "-w -O2 -fomit-frame-pointer")
set(CMAKE_C_FLAGS_DEBUG "-O0 -g -DDEBUG")
set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})
set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})

set(pascal_compiler_flags_cmn "-B" "-FE../bin" "-Fl../bin/" "-Cs2000000" "-vwi")

if(Optz)
	set(pascal_compiler_flags_cmn "-O2" "-Xs" "-Nu" "-Si" ${pascal_compiler_flags_cmn})
	set(haskell_compiler_flags_cmn "-w" "-O2")
	if(APPLE AND NOT universal_build)
		set(CMAKE_C_FLAGS_RELEASE "-fPIC -msse2 ${CMAKE_C_FLAGS_RELEASE}")
		set(CMAKE_CXX_FLAGS_RELEASE "-fPIC -msse2 ${CMAKE_CXX_FLAGS_RELEASE}")
		set(pascal_compiler_flags_cmn "-fPIC" ${pascal_compiler_flags_cmn})
		#-Cf7400 for ppc, -CfSSE2 for x86 (but none for x86_64)
	endif()
else(Optz)
	set(pascal_compiler_flags_cmn "-O-" "-gl" "-dDEBUGFILE" "-pg" "-vv" ${pascal_compiler_flags_cmn})
	set(haskell_compiler_flags_cmn "-Wall" "-debug" "-dcore-lint")
endif(Optz)


if(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH ${DATA_INSTALL_DIR}/hedgewars/)
else(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH share/hedgewars/)
endif(DEFINED DATA_INSTALL_DIR)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

set(HEDGEWARS_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set(HEDGEWARS_PROTO_VER 30)

if(WITH_SERVER)
	set(HAVE_NETSERVER true)
	add_subdirectory(gameServer)
else(WITH_SERVER)
	set(HAVE_NETSERVER false)
endif(WITH_SERVER)


add_subdirectory(bin)
#add_subdirectory(openalbridge)
add_subdirectory(QTfrontend)
add_subdirectory(hedgewars)
add_subdirectory(share)
add_subdirectory(tools)

# CPack vars

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Hedgewars, a turn-based strategy")
set(CPACK_PACKAGE_VENDOR "Hedgewars")
set(CPACK_PACKAGE_FILE_NAME "hedgewars-${HEDGEWARS_VERSION}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "hedgewars-src-${HEDGEWARS_VERSION}")
set(CPACK_SOURCE_GENERATOR "TBZ2")
set(CPACK_PACKAGE_EXECUTABLES "hedgewars" "hedgewars")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Hedgewars ${HEDGEWARS_VERSION}")

if(WIN32 AND NOT UNIX)
	set(CPACK_NSIS_DISPLAY_NAME "Hedgewars, a free turn-based strategy game") 
	set(CPACK_NSIS_HELP_LINK "http://www.hedgewars.org/")
	set(CPACK_NSIS_URL_INFO_ABOUT "http://www.hedgewars.org/")
	set(CPACK_NSIS_CONTACT "unC0Rr@gmail.com")
	set(CPACK_NSIS_MODIFY_PATH OFF)
	set(CPACK_GENERATOR "ZIP;NSIS")
else(WIN32 AND NOT UNIX)
	set(CPACK_STRIP_FILES "bin/hedgewars;bin/hwengine")
endif(WIN32 AND NOT UNIX)

set(CPACK_SOURCE_IGNORE_FILES
	"~"
	"\\\\.svn"
	"\\\\.exe$"
	"\\\\.a$"
	"\\\\.dll$"
	"\\\\.xcf$"
	"\\\\.cxx$"
	"\\\\.db$"
	"\\\\.dof$"
	"\\\\.cmake$"
	"\\\\.layout$"
	"\\\\.zip$"
	"\\\\.gz$"
	"\\\\.bz2$"
	"\\\\.tmp$"
	"\\\\.core$"
	"\\\\.sh$"
	"\\\\.ppu$"
	"\\\\.o$"
	"Makefile"
	"Doxyfile"
	"CMakeFiles"
	"debug"
	"release$"
	"Debug$"
	"Release$"
	"proto.inc$"
	"hwconsts.cpp$"
	"playlist.inc$"
	"CPack"
	"^${PROJECT_SOURCE_DIR}/bin/[a-z]"
	"^${PROJECT_SOURCE_DIR}/tools/templates"
	"^${PROJECT_SOURCE_DIR}/doc"
	"^${PROJECT_SOURCE_DIR}/templates"
	"^${PROJECT_SOURCE_DIR}/Graphics"
	"^${PROJECT_SOURCE_DIR}/realtest"
	"^${PROJECT_SOURCE_DIR}/tmp"
	"^${PROJECT_SOURCE_DIR}/utils"
	"^${PROJECT_SOURCE_DIR}/share/hedgewars/Data/Maps/test"
	"^${PROJECT_SOURCE_DIR}/share/hedgewars/Data/Themes/ethereal"
	"^${PROJECT_SOURCE_DIR}/install_manifest.txt"
	"^${PROJECT_SOURCE_DIR}/CMakeCache.txt"
	"^${PROJECT_SOURCE_DIR}/hedgewars\\\\."
)

include(CPack)
