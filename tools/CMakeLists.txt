if(NOT APPLE)
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
                   "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
                    IMMEDIATE @ONLY)

    add_custom_target(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()

if(APPLE AND NOT SKIPBUNDLE)
    find_package(Qt5 REQUIRED QUIET COMPONENTS Core Widgets Gui Network)
    find_package(SDL2 REQUIRED)
    find_package(SDL2_image 2 REQUIRED)
    find_package(SDL2_net 2 REQUIRED)
    find_package(SDL2_ttf 2 REQUIRED)
    find_package(SDL2_mixer 2 REQUIRED)
    find_package(OggVorbis REQUIRED)
    find_package(PNG REQUIRED)

    if(NOT NOAUTOUPDATE)
        find_package(Sparkle) #needed for SPARKLE_FOUND variable
        #needed because the 'if' clause in the script prints silly policy warnings
        if(SPARKLE_FOUND)
            set(SPARKLE_FOUND 1)
        else()
            set(SPARKLE_FOUND 0)
        endif()
    endif()

    #remove the ";-framework Cocoa" from the SDL2_LIBRARY variable
    string(REGEX REPLACE "(.*);-.*" "\\1" sdl_library_only "${SDL2_LIBRARY}")
    #remove the "libSDLmain.a" from the SDL2_LIBRARY variable
    string(REGEX REPLACE ".*;(.*)" "\\1" sdl_library_only "${sdl_library_only}")

    #get the neme of the library (harmelss if it is static)
    string(REGEX REPLACE ".*/(.*)$" "\\1" PNG_LIBNAME "${PNG_LIBRARY}")
    string(REGEX REPLACE ".*/(.*)$" "\\1" ZLIB_LIBNAME "${ZLIB_LIBRARY}")

    set(frameworks_dir ${CMAKE_INSTALL_PREFIX}/${target_library_install_dir})
    
    if(${BUILD_ENGINE_LIBRARY})
        set(engine_full_path "${frameworks_dir}/${CMAKE_SHARED_LIBRARY_PREFIX}hwengine${CMAKE_SHARED_LIBRARY_SUFFIX}")
    else()
        set(engine_full_path "${CMAKE_INSTALL_PREFIX}/hwengine${CMAKE_EXECUTABLE_SUFFIX}")
    endif()


    #create the .app bundle using BundleUtilities instead of old macdeployqt
    set(APP_DIR "Hedgewars.app")
    set(APP_BASE_DIR "${CMAKE_INSTALL_PREFIX}/../")  # should be, Hedgewars.app/Contents/MacOS/../

    # macro to install qt5 plugins 
    # modified from https://github.com/Kitware/CMake/blob/master/Source/QtDialog/CMakeLists.txt
    macro(install_qt5_plugin _qt_plugin_name _qt_plugins_var)
      get_target_property(_qt_plugin_path "${_qt_plugin_name}" LOCATION)
      if(EXISTS "${_qt_plugin_path}")
        get_filename_component(_qt_plugin_file "${_qt_plugin_path}" NAME)
        get_filename_component(_qt_plugin_type "${_qt_plugin_path}" PATH)
        get_filename_component(_qt_plugin_type "${_qt_plugin_type}" NAME)
        set(_qt_plugin_dir "PlugIns")
        set(_qt_plugin_dest "${_qt_plugin_dir}/${_qt_plugin_type}")
        install(FILES "${_qt_plugin_path}"
          DESTINATION "../${_qt_plugin_dest}" # relative to install dir
          ${COMPONENT})
        list(APPEND ${_qt_plugins_var}
          "\${CMAKE_BINARY_DIR}/${APP_BASE_DIR}/${_qt_plugin_dest}/${_qt_plugin_file}")
      else()
        message(FATAL_ERROR "QT plugin ${_qt_plugin_name} not found")
      endif()
    endmacro()

    # install cocoa plugin and build list to send to fixup_bundle
    install_qt5_plugin("Qt5::QCocoaIntegrationPlugin" QT_PLUGINS)
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/qt.conf"
        "[Paths]\nPlugins = ${_qt_plugin_dir}\n")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/qt.conf"
        DESTINATION "../Resources"  # relative to install dir
        ${COMPONENT})

    # Build up search directories for fixup_bundle
    set(DIRS "")
    # Add QT bin and lib paths
    if(CMAKE_PREFIX_PATH)
        foreach(dir ${CMAKE_PREFIX_PATH})
            list(APPEND DIRS "${dir}/bin" "${dir}/lib")
        endforeach()
    endif()
    # Add other lib folder from around the system
    list(APPEND DIRS 
        ~/Library/Frameworks
        /Library/Frameworks
        /usr/local/lib
        /opt/local/lib
    )

    # operate on the Hedgewars.app
    set(APPS ${CMAKE_BINARY_DIR}/${APP_DIR})
    
    # debugging
    message(STATUS "APPS: ${APPS}")
    message(STATUS "QT_PLUGINS: ${QT_PLUGINS}")
    message(STATUS "DIRS: ${DIRS}")

    # properly fixup the .app to include all dependencies    
    install(CODE "include(BundleUtilities)
        fixup_bundle(\"${APPS}\" \"${QT_PLUGINS}\" \"${DIRS}\")")
    
    
    #create the .dmg for deployment
    #first make sure .app exists, then remove any old .dmg with same name, finally run the script
    add_custom_target(dmg COMMAND make install
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
                                  ${CMAKE_BINARY_DIR}/${APP_DIR}
                          WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
endif()

