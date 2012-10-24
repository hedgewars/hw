find_package(SDL)
find_package(SDL_image)
find_package(SDL_net)
find_package(SDL_ttf)
find_package(SDL_mixer)
find_package(FFMPEG)

include(${CMAKE_MODULE_PATH}/FindSDL_Extras.cmake)

configure_file(${hedgewars_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

#SOURCE AND PROGRAMS SECTION
set(hwengine_project ${hedgewars_SOURCE_DIR}/hedgewars/hwengine.pas)
set(engine_output_name "hwengine")

set(engine_sources
    ${hwengine_project}
    LuaPas.pas
    PNGh.pas
    SDLh.pas
    uAI.pas
    uAIActions.pas
    uAILandMarks.pas
    uAIAmmoTests.pas
    uAIMisc.pas
    uAmmos.pas
    uCaptions.pas
    uChat.pas
    uCollisions.pas
    uCommands.pas
    uCommandHandlers.pas
    uConsole.pas
    uConsts.pas
    uCursor.pas
    uDebug.pas
    uFloat.pas
    uGame.pas
    uGears.pas
    uGearsHandlers.pas
    uGearsHandlersRope.pas
    uGearsHedgehog.pas
    uGearsList.pas
    uGearsRender.pas
    uGearsUtils.pas
    uIO.pas
    uInputHandler.pas
    uLand.pas
    uLandGenMaze.pas
    uLandGraphics.pas
    uLandObjects.pas
    uLandOutline.pas
    uLandPainted.pas
    uLandTemplates.pas
    uLandTexture.pas
    uLocale.pas
    uMisc.pas
    uMobile.pas
    uRandom.pas
    uRender.pas
    uRenderUtils.pas
    uScript.pas
    uSinTable.pas
    uSound.pas
    uStats.pas
    uStore.pas
    uTeams.pas
    uTextures.pas
    uTouch.pas
    uTypes.pas
    uUtils.pas
    uVariables.pas
    uVideoRec.pas
    uVisualGears.pas
    uWorld.pas
    GSHandlers.inc
    VGSHandlers.inc
    ArgParsers.inc
    options.inc
    adler32.pas
    ${CMAKE_CURRENT_BINARY_DIR}/config.inc
    )

if(BUILD_ENGINE_LIBRARY)
    message(STATUS "Engine will be built as library (experimental)")
    set(hwengine_project ${hedgewars_SOURCE_DIR}/hedgewars/hwLibrary.pas)
    set(pascal_flags "-dHWLIBRARY" ${pascal_flags})

    # create position independent code, only required for x68_64 builds, similar to -fPIC
    if(CMAKE_SIZEOF_VOID_P MATCHES "8")
        set(pascal_flags "-Cg" ${pascal_flags})
    endif(CMAKE_SIZEOF_VOID_P MATCHES "8")

    # due to compiler/linker issues on Max OS X 10.6 -k-no_order_inits is needed to avoid linking fail
    if(APPLE AND current_macosx_version GREATER "10.5")
        set(pascal_flags "-k-no_order_inits" ${pascal_flags})
    endif()

    if (APPLE)
        set(engine_output_name "hwengine.dylib")
    endif (APPLE)
endif(BUILD_ENGINE_LIBRARY)

IF(FPC)
    set(fpc_executable ${FPC})
ELSE()
    find_program(fpc_executable fpc)
ENDIF()

if(fpc_executable)
    exec_program(${fpc_executable} ARGS "-iV" OUTPUT_VARIABLE fpc_output)
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

    #on OSX we need to provide the SDL_main() function when building as executable
    if(NOT BUILD_ENGINE_LIBRARY)
        #let's look for the installed sdlmain file; if it is not found, let's build our own
        find_package(SDL REQUIRED)
        #remove the ";-framework Cocoa" from the SDL_LIBRARY variable
        string(REGEX REPLACE "(.*);-.*" "\\1" sdl_dir "${SDL_LIBRARY}")
        #find libsdmain.a
        find_file(SDLMAIN_LIB libSDLMain.a PATHS ${sdl_dir}/Resources/)

        if(SDLMAIN_LIB MATCHES "SDLMAIN_LIB-NOTFOUND")
            include_directories(${SDL_INCLUDE_DIR})
            add_library (SDLmain STATIC SDLMain.m)
            #add a dependency to the hwengine target
            set(engine_sources ${engine_sources} SDLmain)
            set(SDLMAIN_LIB "${LIBRARY_OUTPUT_PATH}/libSDLmain.a")
        endif()

        set(pascal_flags "-k${SDLMAIN_LIB}" ${pascal_flags})
    endif()
endif(APPLE)


#PASCAL DETECTION SECTION
string(REGEX MATCH "[0-9]+\\.[0-9]+\\.[0-9]+" fpc_version "${fpc_output}")

if(fpc_version)
    string(REGEX REPLACE "([0-9]+)\\.[0-9]+\\.[0-9]+" "\\1" fpc_vers_major "${fpc_version}")
    string(REGEX REPLACE "[0-9]+\\.([0-9]+)\\.[0-9]+" "\\1" fpc_vers_minor "${fpc_version}")
    string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)" "\\1" fpc_vers_patch "${fpc_version}")
    message(STATUS "Freepascal version installed: ${fpc_vers_major}.${fpc_vers_minor}")
    math(EXPR fpc_version "${fpc_vers_major}*10000 + ${fpc_vers_minor}*100 + ${fpc_vers_patch}")

    if(fpc_version LESS "020200")
        message(FATAL_ERROR "Minimum required version of FreePascal is 2.2.0")
    elseif(APPLE AND (fpc_version LESS "020600"))
        message(FATAL_ERROR "Minimum required version of FreePascal is 2.6.0 on Mac OS X")
    endif()
else()
    message(FATAL_ERROR "No FreePascal compiler found!")
endif()


#DEPENDECIES AND EXECUTABLES SECTION
if(NOT NOPNG)
    find_package(PNG)
    if(${PNG_FOUND})
        set(pascal_flags "-dPNG_SCREENSHOTS" ${pascal_flags})
        if(APPLE)  # easier to explictly link with the static lib
            string(REGEX REPLACE "(.*)libpng.*" "\\1" PNG_LIBDIR "${PNG_LIBRARY}")
            set(pascal_flags "-k${PNG_LIBDIR}/libpng.a" ${pascal_flags})
        endif()
    else()
        message(STATUS "Screenshots will be in BMP format because libpng was not found")
    endif()
else()
    message(STATUS "Screenshots will be in BMP format per user request")
endif()



#this command is a workaround to some inlining issues present in older FreePascal versions and fixed in 2.6
if(fpc_version LESS "020600")
    add_custom_target(ENGINECLEAN COMMAND ${CMAKE_BUILD_TOOL} "clean" "${PROJECT_BINARY_DIR}" "${hedgewars_SOURCE_DIR}/hedgewars")
endif()


if(NOT NOVIDEOREC)
    if(${FFMPEG_FOUND})
        message(STATUS "Found FFMPEG: ${FFMPEG_LIBRARIES}")
        include_directories(${FFMPEG_INCLUDE_DIR})
        set(pascal_flags "-dUSE_VIDEO_RECORDING" ${pascal_flags})
        IF (WIN32)
            # there are some problems with linking our avwrapper as static lib, so link it as shared
            add_library(avwrapper SHARED avwrapper.c)
            target_link_libraries(avwrapper ${FFMPEG_LIBRARIES})
            install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/${CMAKE_SHARED_LIBRARY_PREFIX}avwrapper${CMAKE_SHARED_LIBRARY_SUFFIX}" DESTINATION ${target_dir})
        ELSE()
            add_library(avwrapper STATIC avwrapper.c)
            set(pascal_flags "-k${FFMPEG_LIBAVCODEC}" "-k${FFMPEG_LIBAVFORMAT}" "-k${FFMPEG_LIBAVUTIL}" ${pascal_flags})
         #   set(pascal_flags "-k${LIBRARY_OUTPUT_PATH}/${CMAKE_STATIC_LIBRARY_PREFIX}avwrapper${CMAKE_STATIC_LIBRARY_SUFFIX}" ${pascal_flags})
        ENDIF()
        if(fpc_version LESS "020600")
            add_dependencies(avwrapper ENGINECLEAN)
        endif()
    else()
        message(STATUS "Could NOT find FFMPEG, video recording will be disabled")
    endif()
else()
    message(STATUS "Video recording disabled by user")
endif()

set(fpc_flags ${noexecstack_flags} ${pascal_flags} ${hwengine_project})

IF(NOT APPLE)
    #here is the command for standard executables or for shared library
    add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}${CMAKE_EXECUTABLE_SUFFIX}"
        COMMAND "${fpc_executable}"
        ARGS ${fpc_flags}
        MAIN_DEPENDENCY ${hwengine_project}
        DEPENDS ${engine_sources}
        )
ELSE()
    #these are the dependencies for building a universal binary on Mac OS X
    foreach (build_arch ${powerpc_build} ${i386_build} ${x86_64_build})
        set(lipo_args_list "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}" ${lipo_args_list})
        add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}"
            COMMAND "${fpc_executable}"
            ARGS ${fpc_flags} -ohwengine.${build_arch} -P${build_arch}
            MAIN_DEPENDENCY ${hwengine_project}
            DEPENDS ${engine_sources}
            )
        add_custom_target(hwengine.${build_arch} ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}")
    endforeach()

    add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}"
        COMMAND "lipo"
        ARGS ${lipo_args_list} -create -output ${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}
        DEPENDS ${lipo_args_list}
        )
ENDIF()


add_custom_target(${engine_output_name} ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}${CMAKE_EXECUTABLE_SUFFIX}")

#when system Lua is not found we need to compile it before engine
if(NOT LUA_FOUND)
    add_dependencies(${engine_output_name} lua)
endif()

#this command is a workaround to some inlining issues present in older FreePascal versions and fixed in 2.6
if(fpc_version LESS "020600")
    if(NO_VIDEOREC OR NOT ${FFMPEG_FOUND})
        add_dependencies(${engine_output_name} ENGINECLEAN)
    endif()
endif()

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_dir})
