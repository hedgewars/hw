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
IF(NOT WITH_SERVER)
	SET(WITH_SERVER 0)
ENDIF(NOT WITH_SERVER)
IF(NOT BUILD_ENGINE_LIBRARY)
	SET(BUILD_ENGINE_LIBRARY 0)
ENDIF(NOT BUILD_ENGINE_LIBRARY)
set(target_dir "bin")


#bundle .app setup
if(APPLE)
	set(CMAKE_FIND_FRAMEWORK "FIRST")

	#paths for creating the bundle
	set(bundle_name Hedgewars.app)
	set(frameworks_dir ${bundle_name}/Contents/Frameworks/)
	set(CMAKE_INSTALL_PREFIX ${bundle_name}/Contents/MacOS/)
	set(DATA_INSTALL_DIR "../Resources/")
	set(target_dir ".")

	#what system are we building for
	set(minimum_macosx_version $ENV{MACOSX_DEPLOYMENT_TARGET})

	#detect on which system are we
	EXEC_PROGRAM("/usr/bin/sw_vers" ARGS "-productVersion" OUTPUT_VARIABLE current_macosx_version)
	STRING(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" current_macosx_version ${current_macosx_version})

	#if nothing is set, we deploy only for the current system
	if(NOT minimum_macosx_version)
		set(minimum_macosx_version ${current_macosx_version})
	endif()

	#lower systems don't have enough processing power anyways
	if (minimum_macosx_version LESS "10.4")
		message(FATAL_ERROR "Hedgewars is not supported on Mac OS X pre-10.4")
	endif()

	#this variable needs to be set for freepascal universal binary
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

	#be sure to select ppc-compatible toolchains just in case
	if(minimum_macosx_version LESS "10.6")
		set(CMAKE_C_COMPILER "gcc-4.0")
		set(CMAKE_CXX_COMPILER "g++-4.0")
	endif()

	if(minimum_macosx_version MATCHES "10.4")
		set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX10.4u.sdk/")
		#workaround for http://playcontrol.net/ewing/jibberjabber/big_behind-the-scenes_chang.html#SDL_mixer (Update 2)
		if(current_macosx_version MATCHES "10.4")
			find_package(SDL_mixer REQUIRED)
			set(pascal_compiler_flags_cmn "-k-dylib_file @loader_path/Frameworks/smpeg.framework/Versions/A/smpeg:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/smpeg.framework/Versions/A/smpeg" "-k-dylib_file @loader_path/Frameworks/mikmod.framework/Versions/A/mikmod:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/mikmod.framework/Versions/A/mikmod" ${pascal_compiler_flags_cmn})
			set(CMAKE_C_FLAGS "-dylib_file @loader_path/Frameworks/smpeg.framework/Versions/A/smpeg:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/smpeg.framework/Versions/A/smpeg -dylib_file @loader_path/Frameworks/mikmod.framework/Versions/A/mikmod:${SDLMIXER_LIBRARY}/Versions/A/Frameworks/mikmod.framework/Versions/A/mikmod")
		endif()
	else()
		STRING(REGEX REPLACE "([0-9]+.[0-9]+).[0-9]+" "\\1" sdk_version ${minimum_macosx_version})
		set(CMAKE_OSX_SYSROOT "/Developer/SDKs/MacOSX${sdk_version}.sdk/")
	endif()

	#add user framework directory
	set(pascal_compiler_flags_cmn "-Ff~/Library/Frameworks" ${pascal_compiler_flags_cmn})
	#set deployment target
	set(pascal_compiler_flags_cmn "-k-macosx_version_min" "-k${minimum_macosx_version}" "-XR${CMAKE_OSX_SYSROOT}" ${pascal_compiler_flags_cmn})
	#link with libsdlmain.a (when building an executable)
	if(NOT BUILD_ENGINE_LIBRARY)
		set(pascal_compiler_flags_cmn "-k${CMAKE_BINARY_DIR}/bin/libSDLmain.a" ${pascal_compiler_flags_cmn})
	endif()

	message(STATUS "Build system: Mac OS X ${current_macosx_version} with GCC:${CMAKE_C_COMPILER}")
	message(STATUS "Target system: Mac OS X ${minimum_macosx_version} for architecture(s):${CMAKE_OSX_ARCHITECTURES}")
endif(APPLE)


#build Debug only when explicitally set
if (NOT CMAKE_BUILD_TYPE)
	set (CMAKE_BUILD_TYPE RELEASE CACHE STRING "Choose the type of build, options are: Debug Release." FORCE)
endif (NOT CMAKE_BUILD_TYPE)

if(CMAKE_BUILD_TYPE MATCHES DEBUG OR CMAKE_BUILD_TYPE MATCHES "Debug" OR CMAKE_BUILD_TYPE MATCHES "debug")
	message(STATUS "Building Debug")
	set(Optz false)
else()
	message(STATUS "Building Release")
	set(Optz true)
endif()


#set default flags values for all projects
set(CMAKE_C_FLAGS "-pipe ${CMAKE_C_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE "-w -Os -fomit-frame-pointer ${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_DEBUG "-Wall -O0 -g -DDEBUG ${CMAKE_C_FLAGS_DEBUG}")
set(CMAKE_CXX_FLAGS ${CMAKE_C_FLAGS})
set(CMAKE_CXX_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE})
set(CMAKE_CXX_FLAGS_DEBUG ${CMAKE_C_FLAGS_DEBUG})

separate_arguments(FPFLAGSINT UNIX_COMMAND ${FPFLAGS})
set(pascal_compiler_flags_cmn ${FPFLAGSINT} "-B" "-FE../bin" "-Cs2000000" "-vewn" ${pascal_compiler_flags_cmn})
set(haskell_compiler_flags_cmn "-O2" ${haskell_compiler_flags_cmn})

if(Optz)
#	set(pascal_compiler_flags_cmn "-O3" "-OpPENTIUM4" "-CfSSE3" "-Xs" "-Si" ${pascal_compiler_flags_cmn})
	set(pascal_compiler_flags_cmn "-Os" "-Ooregvar" "-Xs" "-Si" ${pascal_compiler_flags_cmn})
	set(haskell_compiler_flags_cmn "-w" "-fno-warn-unused-do-bind" ${haskell_compiler_flags_cmn})
else(Optz)
	set(pascal_compiler_flags_cmn "-O-" "-g" "-gl" "-gv" "-Ct" "-dDEBUGFILE" ${pascal_compiler_flags_cmn})
	set(haskell_compiler_flags_cmn "-Wall" "-debug" "-dcore-lint" "-fno-warn-unused-do-bind" ${haskell_compiler_flags_cmn})
endif(Optz)


if(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH ${DATA_INSTALL_DIR}/hedgewars/)
else()
	set(SHAREPATH share/hedgewars/)
endif()
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)


if(WITH_SERVER)
	find_program(ghc_executable ghc)

	if(ghc_executable)
		set(HAVE_NETSERVER true)
		add_subdirectory(gameServer)
	else()
		message(STATUS "No GHC executable found, server will *not* be built")
		set(HAVE_NETSERVER false)
	endif()
else(WITH_SERVER)
	set(HAVE_NETSERVER false)
endif(WITH_SERVER)

find_package(Lua)
if(NOT ${LUA_FOUND})
        message(STATUS "Lua library not found, building bundled dependency")
	add_subdirectory(misc/liblua)
	#link with liblua.a (which requires readline)
	set(pascal_compiler_flags_cmn "-k${CMAKE_BINARY_DIR}/bin/liblua.a" "-k-lreadline" ${pascal_compiler_flags_cmn})
endif()
add_subdirectory(hedgewars)

#run cmake -DBUILD_ANDROID_PORT=1 to enable this
if(ANDROID)
	add_subdirectory(project_files/Android-build)
endif()

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
#	"^${CMAKE_CURRENT_SOURCE_DIR}/misc/libopenalbridge"
#	"^${CMAKE_CURRENT_SOURCE_DIR}/misc/libfreetype"
	"^${CMAKE_CURRENT_SOURCE_DIR}/misc/liblua"
#	"^${CMAKE_CURRENT_SOURCE_DIR}/misc/libtremor"
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

