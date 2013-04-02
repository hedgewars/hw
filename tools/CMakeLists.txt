if (NOT APPLE)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
                   "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
                    IMMEDIATE @ONLY)

    add_custom_target(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()

if (APPLE)
    find_package(Qt4 REQUIRED QUIET)
    find_package(SDL REQUIRED)
    find_package(SDL_image REQUIRED)
    find_package(SDL_net REQUIRED)
    find_package(SDL_ttf REQUIRED)
    find_package(SDL_mixer REQUIRED)
    find_package(OggVorbis REQUIRED)
    if(NOT NOAUTOUPDATE)
        find_package(Sparkle) #needed for SPARKLE_FOUND variable
        #needed because the 'if' clause in the script prints silly policy warnings
        if(${SPARKLE_FOUND})
            set(SPARKLE_FOUND 1)
        else()
            set(SPARKLE_FOUND 0)
        endif()
    endif()

    #use the associated tool from the libraries we've selected
    string(REGEX REPLACE "(.*)/include.*" "\\1" qt_base_dir "${QT_INCLUDE_DIR}")

    #remove the ";-framework Cocoa" from the SDL_LIBRARY variable
    string(REGEX REPLACE "(.*);-.*" "\\1" sdl_library_only "${SDL_LIBRARY}")

    if(NOT NOPNG)
        #get the neme of the library (harmelss if it is static)
        string(REGEX REPLACE ".*/(.*)$" "\\1" PNG_LIBNAME "${PNG_LIBRARY}")
    endif()

    set(frameworks_dir ${CMAKE_INSTALL_PREFIX}/${target_library_install_dir})
    if(${BUILD_ENGINE_LIBRARY})
        set(engine_full_path "${frameworks_dir}/${CMAKE_SHARED_LIBRARY_PREFIX}hwengine${CMAKE_SHARED_LIBRARY_SUFFIX}")
    else()
        set(engine_full_path "${CMAKE_INSTALL_PREFIX}/hwengine${CMAKE_EXECUTABLE_SUFFIX}")
    endif()

    #this tool is present in qt 4.5 but only if you compile from sources
    #from qt 4.6 is present also in the binary version
    find_program(macdeployqt_executable NAMES macdeployqt macdeployqt-mac PATHS ${qt_base_dir}/bin)
    if(NOT macdeployqt_executable)
        message(FATAL_ERROR "The utility macdeployqt is required to create the bundle (seached: ${qt_base_dir})")
    else()
        message(STATUS "Found macdeployqt: ${macdeployqt_executable}")
    endif()

    #dummy target, we're interested in the postscript file
    add_custom_target(bundle)
    set_target_properties(bundle PROPERTIES POST_INSTALL_SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)

    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/CreateMacBundle.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)
endif()

