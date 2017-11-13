
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
set(CPACK_STRIP_FILES true)

if(WIN32 AND NOT UNIX)
    set(CPACK_NSIS_DISPLAY_NAME "Hedgewars")
    set(CPACK_NSIS_HELP_LINK "http://www.hedgewars.org/")
    set(CPACK_NSIS_URL_INFO_ABOUT "http://www.hedgewars.org/")
    set(CPACK_NSIS_CONTACT "unC0Rr@gmail.com")
    set(CPACK_NSIS_MODIFY_PATH OFF)
    set(CPACK_NSIS_EXECUTABLES_DIRECTORY ".")
    set(CPACK_NSIS_MUI_FINISHPAGE_RUN "hedgewars${CMAKE_EXECUTABLE_SUFFIX}")
    set(CPACK_NSIS_CREATE_ICONS "CreateShortCut '$SMPROGRAMS\\\\$STARTMENU_FOLDER\\\\Hedgewars.lnk' '$INSTDIR\\\\hedgewars.exe'")
    set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "hedgewars")
endif(WIN32 AND NOT UNIX)

set(CPACK_SOURCE_IGNORE_FILES
    #temporary files
    "~"
    ".swp"
    #version control
    "\\\\.hg"
    "\\\\.git"
    "\\\\.orig$"
    #output binary/library
    "\\\\.exe$"
    "\\\\.a$"
    "\\\\.so$"
    "\\\\.dylib$"
    "\\\\.dll$"
    "\\\\.ppu$"
    "\\\\.o$"
    "\\\\.cxx$"
    "\\\\.hi$"
    #graphics
    "\\\\.xcf$"
    "\\\\.svg$"
    "\\\\.svgz$"
    "\\\\.psd$"
    "\\\\.sifz$"
    #misc
    "\\\\.core$"
    "\\\\.layout$"
    "\\\\.db$"
    "\\\\.dof$"
    "\\\\.or$"
    "\\\\.stackdump$"
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
    #qt extra files
    "moc_.*\\\\.cxx_parameters"
    "\\\\.qrc.depends$"
    "\\\\.qm$"
    #other cmake generated files
    "Makefile$"
    "Doxyfile"
    "CMakeFiles"
    "[dD]ebug$"
    "[rR]elease$"
    "CPack"
    "CTestTestfile.cmake"
    "gameServer2"
    "cmake_install\\\\.cmake$"
    "cmake_uninstall\\\\.cmake$"
    "CMakeCache\\\\.txt$"
    "build_windows_.*\\\\.bat$"
    "arch\\\\.c$"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/liblua"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/frontlib"
#    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/cmdlineClient"
    "^${CMAKE_CURRENT_SOURCE_DIR}/misc/winutils/bin"
    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/promotional_art"
    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/AudioMono"
    "^${CMAKE_CURRENT_SOURCE_DIR}/project_files/HedgewarsMobile"
    "^${CMAKE_CURRENT_SOURCE_DIR}/tools/templates"
    "^${CMAKE_CURRENT_SOURCE_DIR}/tools/drawMapTest"
    "^${CMAKE_CURRENT_SOURCE_DIR}/doc"
    "^${CMAKE_CURRENT_SOURCE_DIR}/tmp"
    "^${CMAKE_CURRENT_SOURCE_DIR}/utils"
    "^${CMAKE_CURRENT_SOURCE_DIR}/share/hedgewars/Data/Maps/test"
    "^${CMAKE_CURRENT_SOURCE_DIR}/install_manifest.txt"
    "^${CMAKE_CURRENT_SOURCE_DIR}/CMakeCache.txt"
    "^${CMAKE_CURRENT_SOURCE_DIR}/hedgewars\\\\."
)

include(CPack)
