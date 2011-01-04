project(hedgewars)

cmake_minimum_required(VERSION 2.6.0 FATAL_ERROR)
cmake_policy(SET CMP0003 NEW)

IF(POLICY CMP0012)
	cmake_policy(SET CMP0012 NEW)
ENDIF()

#detect Mercurial revision (if present)
set(version_suffix "-dev") #UNSET THIS VARIABLE AT RELEASE TIME
IF(version_suffix MATCHES "-dev")
	set(HW_DEV true)
	IF (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.hg)
		FIND_PROGRAM(HGCOMMAND hg)
		IF(HGCOMMAND)
			exec_program(${HGCOMMAND}
				     ARGS identify -in ${CMAKE_CURRENT_SOURCE_DIR}
				     OUTPUT_VARIABLE version_suffix
				     )
			STRING(REGEX REPLACE "([0-9a-zA-Z]+)(.*) ([0-9]+)(.*)" "\\3:\\1" version_suffix ${version_suffix})
			MESSAGE(STATUS "Building revision ${version_suffix}")
			set(version_suffix "-${version_suffix}")
		ENDIF()
	ENDIF()
ELSE()
	set(HW_DEV false)
ENDIF()

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules)

set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "9")
set(CPACK_PACKAGE_VERSION_PATCH "15${version_suffix}")

#forbid in-tree building
#IF (${CMAKE_SOURCE_DIR} MATCHES ${CMAKE_BINARY_DIR})
#	MESSAGE(STATUS "Please do an out-of-tree build:")
#	MESSAGE(STATUS "rm CMakeCache.txt; mkdir build; cd build; cmake ..; make")
#	MESSAGE(FATAL_ERROR "In-tree-build detected!")
#ENDIF (${CMAKE_SOURCE_DIR} MATCHES ${CMAKE_BINARY_DIR})

#set some safe values
IF(NOT WITH_SERVER)
	SET(WITH_SERVER 0)
ENDIF(NOT WITH_SERVER)
IF(NOT BUILD_ENGINE_LIBRARY)
	SET(BUILD_ENGINE_LIBRARY 0)
ENDIF(NOT BUILD_ENGINE_LIBRARY)


if(APPLE)
	set(CMAKE_FIND_FRAMEWORK "FIRST")

	#paths for creating the bundle
	set(bundle_name Hedgewars.app)
	set(CMAKE_INSTALL_PREFIX ${bundle_name}/Contents/MacOS/)
	set(DATA_INSTALL_DIR "../Resources/")
	set(target_dir ".")

	#what system are we building for
	set(minimum_macosx $ENV{MACOSX_DEPLOYMENT_TARGET})

	#detect on which system are we
	EXEC_PROGRAM("/usr/bin/sw_vers" OUTPUT_VARIABLE MACOSX_VERSION_TMP)
	STRING(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" MACOSX_VERSION_TMP "${MACOSX_VERSION_TMP}")
	STRING(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" current_macosx_version ${MACOSX_VERSION_TMP})

	if(NOT minimum_macosx)
		#if nothing is set, we deploy only for the current system
		set(minimum_macosx ${current_macosx_version})
	endif()

	if (minimum_macosx LESS "10.4")
		set(FATAL "Hedgewars is not supported for pre-10.4 systems")
	endif()

	set(CMAKE_OSX_ARCHITECTURES "i386;ppc7400")


	#create universal binaries only when it's time to bundle the application, also build server
	IF(BUNDLE)
		set(WITH_SERVER true)
		if(NOT minimum_macosx MATCHES "10.6")
			set(CMAKE_C_COMPILER "gcc-4.0")
			set(CMAKE_CXX_COMPILER "g++-4.0")
		else()
			if(current_macosx_version MATCHES "10.6")
				set(CMAKE_OSX_ARCHITECTURES "x86_64")
			endif()
		endif()
	ELSE()
		if(current_macosx_version MATCHES "10.6")
			set(CMAKE_OSX_ARCHITECTURES "x86_64")
		endif()
	ENDIF()

	message(STATUS "Target system: Mac OS X ${minimum_macosx} ${CMAKE_OSX_ARCHITECTURES}")

	if(minimum_macosx MATCHES "10.4")
		set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.4u.sdk/")
		if(current_macosx_version MATCHES "10.4")
			find_package(SDL_mixer REQUIRED)
			set(pascal_compiler_flags_cmn "-k-dylib_file @loader_path/Frameworks/smpeg.framework/Versions/A/smpeg:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/smpeg.framework/Versions/A/smpeg" "-k-dylib_file @loader_path/Frameworks/mikmod.framework/Versions/A/mikmod:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/mikmod.framework/Versions/A/mikmod" ${pascal_compiler_flags_cmn})
			set(CMAKE_C_FLAGS "-dylib_file @loader_path/Frameworks/smpeg.framework/Versions/A/smpeg:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/smpeg.framework/Versions/A/smpeg -dylib_file @loader_path/Frameworks/mikmod.framework/Versions/A/mikmod:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/mikmod.framework/Versions/A/mikmod")
		endif()
	else()
		set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX${minimum_macosx}.sdk/")
	endif()

	#1.set deployment target; 2.link with libsdlmain.a (when building an executable); 3.link with liblua.a (which requires readline)
	set(pascal_compiler_flags_cmn "-k-macosx_version_min" "-k${minimum_macosx}" "-XR${CMAKE_OSX_SYSROOT}" ${pascal_compiler_flags_cmn})
	if(NOT BUILD_ENGINE_LIBRARY)
		set(pascal_compiler_flags_cmn "-k${CMAKE_BINARY_DIR}/bin/libSDLmain.a" ${pascal_compiler_flags_cmn})
	endif()
	set(pascal_compiler_flags_cmn "-k${CMAKE_BINARY_DIR}/bin/liblua.a" "-k-lreadline" ${pascal_compiler_flags_cmn})
else(APPLE)
	set(target_dir "bin")
endif(APPLE)


#this snippet sets "Release" mode by default
#IF (NOT CMAKE_BUILD_TYPE)
#	SET(CMAKE_BUILD_TYPE "Release")
#ENDIF (NOT CMAKE_BUILD_TYPE)
if (NOT CMAKE_BUILD_TYPE)
	set (CMAKE_BUILD_TYPE RELEASE CACHE STRING "Choose the type of build, options are: None Debug Release." FORCE)
endif (NOT CMAKE_BUILD_TYPE)

if(CMAKE_BUILD_TYPE MATCHES RELEASE OR CMAKE_BUILD_TYPE MATCHES "Release")
	message(STATUS "Building Release")
	set(Optz true)
else()
	message(STATUS "Building Debug")
	#set(CMAKE_VERBOSE_MAKEFILE true)
	set(Optz false)
endif()


#set default flags values for all the project
set(CMAKE_C_FLAGS "-pipe ${CMAKE_C_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE "-w -O2 -fomit-frame-pointer ${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_DEBUG "-Wall -O0 -g -DDEBUG ${CMAKE_C_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})
set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})

set(pascal_compiler_flags_cmn "-B" "-FE../bin" "-Cs2000000" "-vewn" ${pascal_compiler_flags_cmn})

if(Optz)
#	set(pascal_compiler_flags_cmn "-O3" "-OpPENTIUM4" "-CfSSE3" "-Xs" "-Si" ${pascal_compiler_flags_cmn})
	set(pascal_compiler_flags_cmn "-O2" "-Xs" "-Si" ${pascal_compiler_flags_cmn})
	set(haskell_compiler_flags_cmn "-O2" "-w")
else(Optz)
	set(pascal_compiler_flags_cmn "-O-" "-g" "-gh" "-gl" "-dDEBUGFILE" ${pascal_compiler_flags_cmn})
	set(haskell_compiler_flags_cmn "-Wall" "-debug" "-dcore-lint")
endif(Optz)


if(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH ${DATA_INSTALL_DIR}/hedgewars/)
else()
	set(SHAREPATH share/hedgewars/)
endif()
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

set(HEDGEWARS_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set(HEDGEWARS_PROTO_VER 34)

if(WITH_SERVER)
	message(STATUS "Server is going to be built! Make sure you have GHC installed")
	set(HAVE_NETSERVER true)
	add_subdirectory(gameServer)
else(WITH_SERVER)
	set(HAVE_NETSERVER false)
endif(WITH_SERVER)

add_subdirectory(misc/liblua)
add_subdirectory(hedgewars)
#add_subdirectory(misc/libopenalbridge)
if(NOT BUILD_ENGINE_LIBRARY)
	add_subdirectory(bin)
	add_subdirectory(QTfrontend)
	add_subdirectory(share)
	add_subdirectory(tools)
endif()

# CPack vars

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
#   "^${CMAKE_CURRENT_SOURCE_DIR}/misc/libopenalbridge"
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
