configure_file(${hedgewars_SOURCE_DIR}/hedgewars/proto.inc.in ${CMAKE_CURRENT_BINARY_DIR}/proto.inc)

find_package(SDL)
find_package(SDL_image)
find_package(SDL_net)
find_package(SDL_ttf)
find_package(SDL_mixer)


#SOURCE AND PROGRAMS SECTION 
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
	RETURN_VALUE testnoexecstack
	)

if (${testnoexecstack})
	set (noexecstack_flags "")
endif (${testnoexecstack})


#PASCAL DETECTION SECTION
string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" fpc_version "${fpc_output}")

if (fpc_version)
	string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1" fpc_vers_major "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+" "\\1" fpc_vers_minor "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1" fpc_vers_patch "${fpc_version}")
	message(STATUS "Freepascal version detected: ${fpc_vers_major}.${fpc_vers_minor}.${fpc_vers_patch}")
	math(EXPR fpc_ver "${fpc_vers_major}*10000 + ${fpc_vers_minor}*100 + ${fpc_vers_patch}")
	if (fpc_ver LESS "020200")
		message(FATAL_ERROR "Minimum required version of FreePascal is 2.2.0")
	else()
		if (APPLE AND build_x86_64 AND fpc_ver LESS "020400")
			message(FATAL_ERROR "Minimum required version of FreePascal is 2.4.0 for building 64 bit applications")
		endif()
		set(pascal_compiler ${fpc_executable})
	endif ()
endif (fpc_version)

if (NOT pascal_compiler)
	message(FATAL_ERROR "No Pascal compiler found!")
endif (NOT pascal_compiler)


set(pascal_compiler_flags ${noexecstack_flags} ${pascal_compiler_flags_cmn} ${hwengine_project})

if(LOWRES)
	set(pascal_compiler_flags "-dLOWRES" ${pascal_compiler_flags} ${hwengine_project})
endif(LOWRES)


#DEPENDECIES AND EXECUTABLES SECTION
IF(APPLE)
#let's build sdlmain, which is absent from the framework
	find_package(SDL REQUIRED)

	set(LIBRARY_OUTPUT_PATH ${EXECUTABLE_OUTPUT_PATH})
	include_directories(${SDL_INCLUDE_DIR})
	link_libraries(${SDL_LIBRARY})

	add_library (SDLmain STATIC SDLMain.m)
	set(engine_sources SDLmain ${engine_sources})
ENDIF(APPLE)

IF(NOT APPLE)
#here is the standard command for any system
	add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}"
		COMMAND "${pascal_compiler}"
		ARGS ${pascal_compiler_flags}
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS ${engine_sources}
		)
ELSE()
#these are the dependencies for building a universal binary on Mac OS X
	if(build_ppc)
		set(lipo_args_list "${EXECUTABLE_OUTPUT_PATH}/hwengine.ppc" ${lipo_args_list})
	endif()
	if(build_i386)
		set(lipo_args_list "${EXECUTABLE_OUTPUT_PATH}/hwengine.386" ${lipo_args_list})
	endif()
	if(build_x86_64)
		set(lipo_args_list "${EXECUTABLE_OUTPUT_PATH}/hwengine.x64" ${lipo_args_list})
	endif()

	add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.386"
		COMMAND "${pascal_compiler}" 
		ARGS ${pascal_compiler_flags} -ohwengine.386 -Pi386
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS ${engine_sources}
		)
	add_custom_target(hwengine.386 ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.386")

	add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.ppc"
		COMMAND "${pascal_compiler}"
		ARGS ${pascal_compiler_flags} -ohwengine.ppc -Ppowerpc
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS ${engine_sources}
		)
	add_custom_target(hwengine.ppc ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.ppc")

	add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.x64"
		COMMAND "${pascal_compiler}" 
		ARGS ${pascal_compiler_flags} -ohwengine.x64 -Px86_64
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS ${engine_sources}
		)
	add_custom_target(hwengine.x64 ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.x64")

	add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine"
		COMMAND "lipo"
		ARGS ${lipo_args_list} -create -output ${EXECUTABLE_OUTPUT_PATH}/hwengine
		DEPENDS ${lipo_args_list}
		)
ENDIF()


add_custom_target(hwengine ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_dir})

