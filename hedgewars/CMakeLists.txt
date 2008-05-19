configure_file(${hedgewars_SOURCE_DIR}/hedgewars/proto.inc.in 
	${CMAKE_CURRENT_BINARY_DIR}/proto.inc)

set(fpc_tryexe fpc)
set(hwengine_project ${hedgewars_SOURCE_DIR}/hedgewars/hwengine.dpr)

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
	${CMAKE_CURRENT_BINARY_DIR}/playlist.inc
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

string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" fpc_version "${fpc_output}")
if (fpc_version)
	string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1" fpc_vers_major "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.([0-9])+\\.[0-9]+" "\\1" fpc_vers_minor "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1" fpc_vers_patch "${fpc_version}")
	math(EXPR fpc_ver "${fpc_vers_major}*10000 + ${fpc_vers_minor}*100 + ${fpc_vers_patch}")
	if (fpc_ver LESS "010904")
		message("Minimum required version of FreePascal is 1.9.4")
	else (fpc_ver LESS "010904")
		set(pascal_compiler ${fpc_executable})
		set(pascal_compiler_flags ${noexecstack_flags} "-B" "-FE../bin" "-Cs2000000" "-vwi" "-O2" ${hwengine_project})
	endif (fpc_ver LESS "010904")
endif (fpc_version)

if (NOT pascal_compiler)
	message(FATAL_ERROR "No Pascal compiler found!")
endif (NOT pascal_compiler)

add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}"
		COMMAND "${pascal_compiler}"
		ARGS ${pascal_compiler_flags}
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS ${engine_sources}
		)

add_custom_target(hwengine ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION bin)
