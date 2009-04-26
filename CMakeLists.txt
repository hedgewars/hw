project(hedgewars)

cmake_minimum_required(VERSION 2.6.0 FATAL_ERROR)

if(COMMAND cmake_policy)
	cmake_policy(SET CMP0003 NEW)
endif(COMMAND cmake_policy)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules)

set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "9")
set(CPACK_PACKAGE_VERSION_PATCH "11-dev")

set(universal_build "0")

if(APPLE)
set(CMAKE_INSTALL_PREFIX "Hedgewars.app/Contents/MacOS/") 
set(DATA_INSTALL_DIR "../Resources/")

if(CMAKE_OSX_ARCHITECTURES MATCHES "i386;ppc7400" OR CMAKE_OSX_ARCHITECTURES MATCHES "ppc7400;i386" OR CMAKE_OSX_ARCHITECTURES MATCHES "i386;ppc" OR CMAKE_OSX_ARCHITECTURES MATCHES "ppc;i386")
	set(universal_build "1")
	message("-- Building a Universal Application")
endif(CMAKE_OSX_ARCHITECTURES MATCHES "i386;ppc7400" OR CMAKE_OSX_ARCHITECTURES MATCHES "ppc7400;i386" OR CMAKE_OSX_ARCHITECTURES MATCHES "i386;ppc" OR CMAKE_OSX_ARCHITECTURES MATCHES "ppc;i386")

endif(APPLE)

if(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH ${DATA_INSTALL_DIR}/hedgewars/)
else(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH share/hedgewars/)
endif(DEFINED DATA_INSTALL_DIR)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

set(HEDGEWARS_VERSION "${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set(HEDGEWARS_PROTO_VER 26)

if(WITH_SERVER)
	set(HAVE_NETSERVER true)
	add_subdirectory(gameServer)
else(WITH_SERVER)
	set(HAVE_NETSERVER false)
endif(WITH_SERVER)

add_subdirectory(bin)
add_subdirectory(QTfrontend)
add_subdirectory(hedgewars)
add_subdirectory(share)

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
	set(CPACK_NSIS_DISPLAY_NAME "Hedgewars, a turn-based Worms-like strategy") 
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
	"^${PROJECT_SOURCE_DIR}/tools"
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
