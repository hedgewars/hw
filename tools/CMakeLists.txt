if (NOT APPLE)
	CONFIGURE_FILE(
		"${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
		"${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
		IMMEDIATE @ONLY)

	ADD_CUSTOM_TARGET(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake")
endif()

if (APPLE AND BUNDLE)

	find_package(Qt4 REQUIRED)
	find_package(SDL REQUIRED)
	find_package(SDL_image REQUIRED)
	find_package(SDL_net REQUIRED)
	find_package(SDL_ttf REQUIRED)
	find_package(SDL_mixer REQUIRED)
	find_package(OGGVORBIS REQUIRED)
	find_package(SPARKLE)

	#use the associated tool from the libraries we've selected
	string(REGEX REPLACE "(.*)/include;-.*" "\\1" qt_base_dir "${QT_INCLUDE_DIR}")
	find_program(macdeployqt_EXE NAMES macdeployqt macdeployqt-mac PATH ${qt_base_dir})

	if(NOT macdeployqt_EXE)
		message(FATAL_ERROR "The utility macdeployqt is required to create the bundle!")
	endif()

	#dummy target, we're interested in the postscript file
	add_custom_target(bundle)

	set_target_properties(bundle PROPERTIES POST_INSTALL_SCRIPT ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)

	set(frameworks_dir ${bundle_name}/Contents/Frameworks/)

	string(REGEX REPLACE "(.*);-.*" "\\1" sdl_dir "${SDL_LIBRARY}")

	if(SPARKLE_FOUND)
		set(SPARKLE_FOUND 1)
	else()
		set(SPARKLE_FOUND 0)
	endif()

	CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/CreateMacBundle.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/CreateMacBundle.cmake)

endif(APPLE AND BUNDLE)
