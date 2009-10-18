if (APPLE AND BUNDLE)

find_package(OGGVORBIS)
find_program(macdeployqt_EXE NAMES macdeployqt macdeployqt-mac)

if(NOT macdeployqt_EXE)
	message(FATAL_ERROR "The utility macdeployqt is required to create the bundle!")
endif()

#dummy target, we're interested in the postscript
add_custom_target(bundle)

set_target_properties(bundle PROPERTIES POST_INSTALL_SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)

set(frameworks_dir ${bundle_name}/Contents/Frameworks/)

string(REGEX REPLACE "(.*);-.*" "\\1" sdl_dir "${SDL_LIBRARY}")

CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/CreateMacBundle.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)

endif(APPLE AND BUNDLE)
