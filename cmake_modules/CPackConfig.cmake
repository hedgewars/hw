
# revision information in cpack-generated names
if(CMAKE_BUILD_TYPE MATCHES DEBUG)
    set(full_suffix "${HEDGEWARS_VERSION}-r${HEDGEWARS_REVISION}")
else()
    set(full_suffix "${HEDGEWARS_VERSION}")
endif()

# CPack variables
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Hedgewars, a free turn-based strategy game")
set(CPACK_PACKAGE_VENDOR "Hedgewars Project")
set(CPACK_PACKAGE_FILE_NAME "Hedgewars-${full_suffix}")
set(CPACK_SOURCE_PACKAGE_FILE_NAME "hedgewars-src-${full_suffix}")
set(CPACK_SOURCE_GENERATOR "TBZ2")
set(CPACK_PACKAGE_EXECUTABLES "hedgewars" "Hedgewars")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/COPYING")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Hedgewars ${full_suffix}")

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

