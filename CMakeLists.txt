project(hedgewars)

cmake_minimum_required(VERSION 2.4.0)

set(SHAREPATH ${DATA_INSTALL_DIR}/hedgewars/)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

add_subdirectory(bin)
add_subdirectory(QTfrontend)
add_subdirectory(hedgewars)
add_subdirectory(share)

set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Hedgewars, a turn-based strategy")
set(CPACK_PACKAGE_VENDOR "Hedgewars")
set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "8")
set(CPACK_PACKAGE_VERSION_PATCH "0")
set(CPACK_PACKAGE_FILE_NAME "hedgewars-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}")
set(CPACK_PACKAGE_EXECUTABLES "hedgewars" "hedgewars")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/COPYING.txt")
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

include(CPack)

