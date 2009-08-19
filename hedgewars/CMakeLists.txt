configure_file(${hedgewars_SOURCE_DIR}/hedgewars/proto.inc.in ${CMAKE_CURRENT_BINARY_DIR}/proto.inc)

set(fpc_tryexe fpc)
set(hwengine_project ${hedgewars_SOURCE_DIR}/hedgewars/hwengine.pas)

set(engine_sources
	${hwengine_project}
	SDLh.pas
	uAI.pas
	uAIActions.pas
	uAIAmmoTests.pas
	uAIMisc.pas
	uAmmos.pas
	uChat.pas
	uCollisions.pas
	uConsole.pas
	uConsts.pas
	uFloat.pas
	uGame.pas
	uGears.pas
	uIO.pas
	uKeys.pas
	uLand.pas
	uLandGraphics.pas
	uLandObjects.pas
	uLandTemplates.pas
	uLandTexture.pas
	uLocale.pas
	uMisc.pas
	uRandom.pas
	uSHA.pas
	uSound.pas
	uStats.pas
	uStore.pas
	uTeams.pas
	uTriggers.pas
	uVisualGears.pas
	uWorld.pas
	CCHandlers.inc
	GSHandlers.inc
	HHHandlers.inc
	SinTable.inc
	options.inc
	${CMAKE_CURRENT_BINARY_DIR}/proto.inc
	tunsetborder.inc
	)

find_program(fpc_executable ${fpc_tryexe})

if (fpc_executable)
	 exec_program(${fpc_executable} ARGS "-h" OUTPUT_VARIABLE fpc_output)
endif (fpc_executable)

set (noexecstack_flags "-k-z" "-knoexecstack")
file(WRITE ${EXECUTABLE_OUTPUT_PATH}/checkstack.pas "begin end.")

exec_program(${fpc_executable} ${EXECUTABLE_OUTPUT_PATH}
		ARGS ${noexecstack_flags} checkstack.pas
		OUTPUT_VARIABLE noout
		RETURN_VALUE testnoexecstack)

if (${testnoexecstack})
set (noexecstack_flags "")
endif (${testnoexecstack})

IF(APPLE)
	FIND_PACKAGE(SDL)

	if (SDL_FOUND)
		set(LIBRARY_OUTPUT_PATH ${EXECUTABLE_OUTPUT_PATH})
		include_directories(${SDL_INCLUDE_DIR})
		link_libraries(${SDL_LIBRARY})

		add_library (SDLmain STATIC SDLMain.m)
		set(engine_sources SDLmain ${engine_sources})
	else (SDL_FOUND)
		message(FATAL_ERROR "No SDL framework found!")
	endif (SDL_FOUND)
ENDIF(APPLE)

string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" fpc_version "${fpc_output}")
if (fpc_version)
	string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1" fpc_vers_major "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.([0-9])+\\.[0-9]+" "\\1" fpc_vers_minor "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1" fpc_vers_patch "${fpc_version}")
	math(EXPR fpc_ver "${fpc_vers_major}*10000 + ${fpc_vers_minor}*100 + ${fpc_vers_patch}")
	if (fpc_ver LESS "020200")
		message("Minimum required version of FreePascal is 2.2.0")
	else (fpc_ver LESS "020200")
		set(pascal_compiler ${fpc_executable})
		if(NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE MATCHES "Release")
			set(pascal_compiler_flags ${noexecstack_flags} "-B" "-FE../bin" "-Fl../bin/" "-Cs2000000" "-vwi" "-O2" "-Xs" ${hwengine_project})
		else()
			set(pascal_compiler_flags ${noexecstack_flags} "-B" "-FE../bin" "-Fl../bin/" "-Cs2000000" "-vwi" "-O-" "-gl" "-dDEBUGFILE" ${hwengine_project})
		endif()
		if(LOWRES)
			set(pascal_compiler_flags "-dLOWRES" ${pascal_compiler_flags} ${hwengine_project})
		endif(LOWRES)
	endif (fpc_ver LESS "020200")
endif (fpc_version)

if (NOT pascal_compiler)
	message(FATAL_ERROR "No Pascal compiler found!")
endif (NOT pascal_compiler)

#special handling of MSVC compiler (no static linking)
if(MSVC)
	set(pascal_compiler_flags "-dMSVC" ${pascal_compiler_flags})
endif(MSVC)

IF(NOT APPLE OR NOT universal_build)
#here is the standard command for any system
add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}"
		COMMAND "${pascal_compiler}"
		ARGS ${pascal_compiler_flags}
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS openalbridge ${engine_sources}
		)
ELSE()
#these are the two dependencies for building a universal binary on Mac OS X
add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.386"
		COMMAND "ppc386" 
		ARGS ${pascal_compiler_flags} -ohwengine.386
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS openalbridge ${engine_sources}
		)
add_custom_target(hwengine.386 ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.386")

add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.ppc"
		COMMAND "ppcppc"
		ARGS ${pascal_compiler_flags} -ohwengine.ppc
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS openalbridge ${engine_sources}
		)
add_custom_target(hwengine.ppc ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.ppc")

#this is the command that bundles the two executables into one
add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine"
		COMMAND "lipo"
		ARGS ${EXECUTABLE_OUTPUT_PATH}/hwengine.386 ${EXECUTABLE_OUTPUT_PATH}/hwengine.ppc -create -output ${EXECUTABLE_OUTPUT_PATH}/hwengine
		DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.386" "${EXECUTABLE_OUTPUT_PATH}/hwengine.ppc"
		)
ENDIF()


add_custom_target(hwengine ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_dir})

