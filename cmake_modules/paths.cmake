#where to build libs and bins
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
#these variables are for non-makefile generators
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${EXECUTABLE_OUTPUT_PATH})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${EXECUTABLE_OUTPUT_PATH})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_PATH})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_DEBUG ${LIBRARY_OUTPUT_PATH})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY_RELEASE ${LIBRARY_OUTPUT_PATH})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_PATH})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_RELEASE ${LIBRARY_OUTPUT_PATH})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY_DEBUG ${LIBRARY_OUTPUT_PATH})

#resource paths
if(UNIX AND NOT APPLE)
    set(target_binary_install_dir "bin" CACHE PATH "install dest for binaries")
    set(target_library_install_dir "lib" CACHE PATH "install dest for libs")

    string(SUBSTRING "${DATA_INSTALL_DIR}" 0 1 sharepath_start)
    if(${sharepath_start} MATCHES "/")
        set(HEDGEWARS_DATADIR "${DATA_INSTALL_DIR}/")
    else()
        set(HEDGEWARS_DATADIR "${CMAKE_INSTALL_PREFIX}/${DATA_INSTALL_DIR}/")
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
        link_directories("${EXECUTABLE_OUTPUT_PATH}" "${CMAKE_SOURCE_DIR}/misc/winutils/bin")
    endif()
endif()


#RPATH SETTINGS
#necessary for dynamic libraries on UNIX, ignored elsewhere

#use, i.e. don't skip the full RPATH for the build tree
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_SKIP_INSTALL_RPATH FALSE)

#it's safe to use our RPATH because it is relative
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)

#add the automatically determined parts of the RPATH
#which point to directories outside the build tree to the install RPATH
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

if(APPLE)
    #@rpath mangling
    set(CMAKE_INSTALL_RPATH "@executable_path/../Frameworks")
    #install_name_tool for libraries
    set(CMAKE_INSTALL_NAME_DIR "@executable_path/../Frameworks")
else(APPLE AND NOT (${CMAKE_INSTALL_PREFIX} MATCHES "/usr"))
    #paths where to find libraries (final slash not optional):
    # - the first is relative to the executable
    # - the second is the same directory of the executable (so it runs in bin/)
    # - the third one is the full path of the system dir
    #source http://www.cmake.org/pipermail/cmake/2008-January/019290.html
    #skip this if the install prefix is the standard one
    set(CMAKE_INSTALL_RPATH "$ORIGIN/../${target_library_install_dir}/:$ORIGIN/:${CMAKE_INSTALL_PREFIX}/${target_library_install_dir}/")
endif(APPLE)
