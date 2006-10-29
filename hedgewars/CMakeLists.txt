set(dcc32_tryexe dcc132.exe)
set(fpc_tryexe fpc)
set(hwengine_project "hwengine.dpr")

set(engine_sources
	${hwengine_project}
	SDLh.pas
	uAI.pas
	uAIActions.pas
	uAIAmmoTests.pas
	uAIMisc.pas
	uAIThinkStack.pas
	uCollisions.pas
	uConsole.pas
	uConsts.pas
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
	uSound.pas
	uStore.pas
	uTeams.pas
	uWorld.pas
	CCHandlers.inc
	GSHandlers.inc
	HHHandlers.inc
	options.inc
	tunsetborder.inc
	)

find_program(dcc32_executable ${dcc32_tryexe})
find_program(fpc_executable ${fpc_tryexe})

if (dcc32_executable)
	 exec_program(${dcc32_executable} ARGS "--version" OUTPUT_VARIABLE dcc32_output)
endif (dcc32_executable)

if (fpc_executable)
	 exec_program(${fpc_executable} ARGS "-h" OUTPUT_VARIABLE fpc_output)
endif (fpc_executable)

string(REGEX MATCH "[0-9]+\\.[0-9]+" dcc32version "${dcc32_output}")
if (dcc32version)
	set(pascal_compiler ${dcc32_executable})
	set(pascal_compiler_flags "-B" "-W" "-E${EXECUTABLE_OUTPUT_PATH}" ${hwengine_project})
else (dcc32version)
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
			set(pascal_compiler_flags "-B" "-Sd" "-Xs" "-OG" "-O2" "-FE${EXECUTABLE_OUTPUT_PATH}" "-Cs2000000" ${hwengine_project})
		endif (fpc_ver LESS "010904")
	endif (fpc_version)
endif (dcc32version)

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
