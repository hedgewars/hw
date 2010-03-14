configure_file(${hedgewars_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

find_package(SDL)
find_package(SDL_image)
find_package(SDL_net)
find_package(SDL_ttf)
find_package(SDL_mixer)
find_package(Lua)

#find which version of SDL_image and SDL_mixer we have (for IMG_Init and Mix_Init)
#if the headers are not installed, the newer apis won't be activated
find_file(sdlmixer_h SDL_mixer.h ${SDLMIXER_INCLUDE_DIR})
if(sdlmixer_h)
file(STRINGS ${sdlmixer_h} sdlmixer_version_tmp REGEX "SDL_MIXER_PATCHLEVEL[\t' ']+[0-9]+")
string(REGEX MATCH ".([0-9]+)" sdlmixer_version "${sdlmixer_version_tmp}")

if(sdlmixer_version GREATER 9)
message(STATUS "Enabling enhanced SDL_Mixer calls")
set(pascal_compiler_flags_cmn "-dSDL_MIXER_NEWER" ${pascal_compiler_flags_cmn})
endif()
endif()

find_file(sdlimage_h SDL_image.h ${SDLIMAGE_INCLUDE_DIR})
if(sdlimage_h)
file(STRINGS ${sdlimage_h} sdlimage_version_tmp REGEX "SDL_IMAGE_PATCHLEVEL[\t' ']+[0-9]+")
string(REGEX MATCH ".([0-9]+)" sdlimage_version "${sdlimage_version_tmp}")

if(sdlimage_version GREATER 7)
message(STATUS "Enabling enhanced SDL_Image calls")
set(pascal_compiler_flags_cmn "-dSDL_IMAGE_NEWER" ${pascal_compiler_flags_cmn})
endif()
endif()

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
	uScript.pas
	uSHA.pas
	uSound.pas
	uStats.pas
	uStore.pas
	uTeams.pas
	uVisualGears.pas
	uWorld.pas
	CCHandlers.inc
	GSHandlers.inc
	HHHandlers.inc
	SinTable.inc
	options.inc
	${CMAKE_CURRENT_BINARY_DIR}/config.inc
	)

find_program(fpc_executable ${fpc_tryexe})

if(fpc_executable)
	 exec_program(${fpc_executable} ARGS "-h" OUTPUT_VARIABLE fpc_output)
endif(fpc_executable)

set(noexecstack_flags "-k-z" "-knoexecstack")
file(WRITE ${EXECUTABLE_OUTPUT_PATH}/checkstack.pas "begin end.")

exec_program(${fpc_executable} ${EXECUTABLE_OUTPUT_PATH}
	ARGS ${noexecstack_flags} checkstack.pas
	OUTPUT_VARIABLE noout
	RETURN_VALUE testnoexecstack
	)

if(${testnoexecstack})
	set (noexecstack_flags "")
endif(${testnoexecstack})


if(APPLE)
	string(REGEX MATCH "[pP][pP][cC]+" powerpc_build "${CMAKE_OSX_ARCHITECTURES}")
	string(REGEX MATCH "[iI]386+" i386_build "${CMAKE_OSX_ARCHITECTURES}")
	string(REGEX MATCH "[xX]86_64+" x86_64_build "${CMAKE_OSX_ARCHITECTURES}")

	if(powerpc_build)
		set(powerpc_build "powerpc")
	endif()
endif(APPLE)


#PASCAL DETECTION SECTION
string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" fpc_version "${fpc_output}")

if(fpc_version)
	string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1" fpc_vers_major "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+" "\\1" fpc_vers_minor "${fpc_version}")
	string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1" fpc_vers_patch "${fpc_version}")
	message(STATUS "Freepascal version detected: ${fpc_vers_major}.${fpc_vers_minor}")
	math(EXPR fpc_ver "${fpc_vers_major}*10000 + ${fpc_vers_minor}*100 + ${fpc_vers_patch}")

	if(fpc_ver LESS "020200")
		message(FATAL_ERROR "Minimum required version of FreePascal is 2.2.0")
	elseif(APPLE AND x86_64_build AND fpc_ver LESS "020400")
		message(FATAL_ERROR "Minimum required version of FreePascal is 2.4.0 for building 64 bit applications!")
	endif()
else()
	message(FATAL_ERROR "No Pascal compiler found!")
endif()

set(pascal_compiler ${fpc_executable})
set(pascal_compiler_flags ${noexecstack_flags} ${pascal_compiler_flags_cmn} ${hwengine_project})


#DEPENDECIES AND EXECUTABLES SECTION
IF(NOT APPLE)
#here is the standard command for any system
	add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}"
		COMMAND "${pascal_compiler}"
		ARGS ${pascal_compiler_flags}
		MAIN_DEPENDENCY ${hwengine_project}
		DEPENDS ${engine_sources}
		)
ELSE()
	#let's build sdlmain, which is absent from the framework
	find_package(SDL REQUIRED)

#	set(CMAKE_OSX_ARCHITECTURES "x86_64;i386;ppc7400")
	set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/bin)
	include_directories(${SDL_INCLUDE_DIR})

	add_library (SDLmain STATIC SDLMain.m)


	#these are the dependencies for building a universal binary on Mac OS X
	foreach (build_arch ${powerpc_build} ${i386_build} ${x86_64_build})
		set(lipo_args_list "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}" ${lipo_args_list})
		add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}"
			COMMAND "${pascal_compiler}"
			ARGS ${pascal_compiler_flags} -ohwengine.${build_arch} -P${build_arch}
			MAIN_DEPENDENCY ${hwengine_project}
			DEPENDS ${engine_sources} SDLmain lua
			)
		add_custom_target(hwengine.${build_arch} ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}")
	endforeach()

	add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine"
		COMMAND "lipo"
		ARGS ${lipo_args_list} -create -output ${EXECUTABLE_OUTPUT_PATH}/hwengine
		DEPENDS ${lipo_args_list}
		)
ENDIF()


add_custom_target(hwengine ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hwengine${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_dir})

