if(NOT APPLE)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
                   "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
                    IMMEDIATE @ONLY)

    add_custom_target(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()

if(APPLE)
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
        if(SPARKLE_FOUND)
            set(SPARKLE_FOUND 1)
        else()
            set(SPARKLE_FOUND 0)
        endif()
    endif()

    #use the associated tool from the libraries we've selected
    string(REGEX REPLACE "(.*)/include.*" "\\1" qt_base_dir "${QT_INCLUDE_DIR}")

    #remove the ";-framework Cocoa" from the SDL_LIBRARY variable
    string(REGEX REPLACE "(.*);-.*" "\\1" sdl_library_only "${SDL_LIBRARY}")
    #remove the "libSDLmain.a" from the SDL_LIBRARY variable
    string(REGEX REPLACE ".*;(.*)" "\\1" sdl_library_only "${sdl_library_only}")

    if(NOT NOPNG)
        #get the neme of the library (harmelss if it is static)
        string(REGEX REPLACE ".*/(.*)$" "\\1" PNG_LIBNAME "${PNG_LIBRARY}")
        string(REGEX REPLACE ".*/(.*)$" "\\1" ZLIB_LIBNAME "${ZLIB_LIBRARY}")
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
    endif()

    #create the .app bundle
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/CreateMacBundle.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)
    install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake
            CODE "message(STATUS \"Your app bundle is ready\")")

    #create the .dmg for deployment
    #first make sure .app exists, then remove any old .dmg with same name, finally run the script
    add_custom_target(dmg COMMAND "if [ ! -a Hedgewars.app ]; then make install\; fi;"
                          COMMAND rm -f ${CMAKE_BINARY_DIR}/Hedgewars-${HEDGEWARS_VERSION}.dmg
                          COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/create-dmg.sh
                                  --volname "Hedgewars ${HEDGEWARS_VERSION}"
                                # --volicon icon.icns
                                  --window-size 600 470
                                  --icon-size 96
                                  --icon "Hedgewars" 190 190
                                  --app-drop-link 410 190
                                  --background "${CMAKE_CURRENT_SOURCE_DIR}/../misc/dmgBackground.png"
                                  ${CMAKE_BINARY_DIR}/Hedgewars-${HEDGEWARS_VERSION}.dmg
                                  ${CMAKE_BINARY_DIR}/Hedgewars.app
                          WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
endif()

