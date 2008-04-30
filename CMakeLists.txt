project(hedgewars)

cmake_minimum_required(VERSION 2.4.4 FATAL_ERROR)

if(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH ${DATA_INSTALL_DIR}/hedgewars/)
else(DEFINED DATA_INSTALL_DIR)
	set(SHAREPATH share/hedgewars/)
endif(DEFINED DATA_INSTALL_DIR)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

set(HEDGEWARS_PROTO_VER 10)

add_subdirectory(bin)
add_subdirectory(QTfrontend)
add_subdirectory(hedgewars)
add_subdirectory(share)

# CPack vars

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Hedgewars, a turn-based strategy")
set(CPACK_PACKAGE_VENDOR "Hedgewars")
set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "9")
set(CPACK_PACKAGE_VERSION_PATCH "3")
set(CPACK_PACKAGE_FILE_NAME "hedgewars-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "hedgewars-src-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set(CPACK_PACKAGE_EXECUTABLES "hedgewars" "hedgewars")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Hedgewars ${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")

if(WIN32 AND NOT UNIX)
	set(CPACK_NSIS_DISPLAY_NAME "Hedgewars, a turn-based Worms-like strategy") 
	set(CPACK_NSIS_HELP_LINK "http://www.hedgewars.org/")
	set(CPACK_NSIS_URL_INFO_ABOUT "http://www.hedgewars.org/")
	set(CPACK_NSIS_CONTACT "unC0Rr@gmail.com")
	set(CPACK_NSIS_MODIFY_PATH ON)
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
	"^${PROJECT_SOURCE_DIR}/netserver"
	"^${PROJECT_SOURCE_DIR}/misc"
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
