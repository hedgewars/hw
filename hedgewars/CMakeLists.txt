find_package(SDL)
find_package(SDL_image)
find_package(SDL_net)
find_package(SDL_ttf)
find_package(SDL_mixer)

include (CheckLibraryExists)
#Mix_Init/Mix_Quit from SDL_mixer 1.2.9
check_library_exists(${SDLMIXER_LIBRARY} Mix_Init "" HAVE_MIXINIT)
if(HAVE_MIXINIT)
    list(APPEND pascal_flags "-dSDL_MIXER_NEWER")
endif()
#IMG_Init/IMG_Quit from SDL_image 1.2.7
check_library_exists(${SDLIMAGE_LIBRARY} IMG_Init "" HAVE_IMGINIT)
if(HAVE_IMGINIT)
    list(APPEND pascal_flags "-dSDL_IMAGE_NEWER")
endif()


configure_file(${hedgewars_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

#SOURCE AND PROGRAMS SECTION
if(${BUILD_ENGINE_LIBRARY})
    set(engine_output_name "${CMAKE_SHARED_LIBRARY_PREFIX}hwengine${CMAKE_SHARED_LIBRARY_SUFFIX}")
    set(hwengine_project ${hedgewars_SOURCE_DIR}/hedgewars/hwLibrary.pas)
else()
    set(engine_output_name "hwengine${CMAKE_EXECUTABLE_SUFFIX}")
    set(hwengine_project ${hedgewars_SOURCE_DIR}/hedgewars/hwengine.pas)
endif()

if (APPLE)
    set(required_fpc_version 2.6)
else()
    set(required_fpc_version 2.2)
endif()

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
    uPhysFSLayer.pas
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

if(${BUILD_ENGINE_LIBRARY})
    message(${WARNING} "Engine will be built as library (experimental)")
    list(APPEND pascal_flags "-dHWLIBRARY")

    # create position independent code, only required for x68_64 builds, similar to -fPIC
    if(CMAKE_SIZEOF_VOID_P MATCHES "8")
        list(APPEND pascal_flags "-Cg")
    endif(CMAKE_SIZEOF_VOID_P MATCHES "8")

    # due to compiler/linker issues on Max OS X 10.6 -k-no_order_inits is needed to avoid linking fail
    if(APPLE AND current_macosx_version VERSION_GREATER "10.5")
        list(APPEND pascal_flags "-k-no_order_inits")
    endif()
    set(destination_dir ${target_library_install_dir})
else(${BUILD_ENGINE_LIBRARY})
    set(destination_dir ${target_binary_install_dir})
endif(${BUILD_ENGINE_LIBRARY})


find_package(FreePascal REQUIRED)
#when cmake-2.6 support is dropped, this ought to be inside FindFreePascal.cmake
if (FREEPASCAL_VERSION VERSION_LESS required_fpc_version)
    message(FATAL_ERROR "Freepascal ${FREEPASCAL_VERSION} is too old, minimum version required is ${required_fpc_version}")
endif()


#DEPENDECIES AND EXECUTABLES SECTION
if(APPLE)
    string(REGEX MATCH "[pP][pP][cC]+" powerpc_build "${CMAKE_OSX_ARCHITECTURES}")
    string(REGEX MATCH "[iI]386+" i386_build "${CMAKE_OSX_ARCHITECTURES}")
    string(REGEX MATCH "[xX]86_64+" x86_64_build "${CMAKE_OSX_ARCHITECTURES}")

    if(powerpc_build)
        set(powerpc_build "powerpc")
    endif()

    #on OSX we need to provide the SDL_main() function when building as executable
    if(NOT ${BUILD_ENGINE_LIBRARY})
        #let's look for the installed sdlmain file; if it is not found, let's build our own
        find_package(SDL REQUIRED)
        #remove the ";-framework Cocoa" from the SDL_LIBRARY variable
        string(REGEX REPLACE "(.*);-.*" "\\1" sdl_library_only "${SDL_LIBRARY}")
        #find libsdmain.a
        find_file(SDLMAIN_LIB libSDLMain.a PATHS ${sdl_library_only}/Resources/)

        if(SDLMAIN_LIB MATCHES "SDLMAIN_LIB-NOTFOUND")
            include_directories(${SDL_INCLUDE_DIR})
            add_library (SDLmain STATIC SDLMain.m)
            #add a dependency to the hwengine target
            list(APPEND engine_sources SDLmain)
            set(SDLMAIN_LIB "${LIBRARY_OUTPUT_PATH}/libSDLmain.a")
        endif()

        list(APPEND pascal_flags "-k${SDLMAIN_LIB}")
    endif()

    #when you have multiple ld installation make sure you get the one bundled with the compiler
    get_filename_component(compiler_dir ${CMAKE_C_COMPILER} PATH)
    list(APPEND pascal_flags "-FD${compiler_dir}")
endif(APPLE)

if(NOT NOPNG)
    find_package(PNG)
    if(${PNG_FOUND})
        list(APPEND pascal_flags "-dPNG_SCREENSHOTS")
        if(APPLE)  # fpc png unit doesn't pull the library (see bug 21833)
            list(APPEND pascal_flags "-k${PNG_LIBRARY}")
        endif()
    else()
        message(${WARNING} "Screenshots will be in BMP format because libpng was not found")
    endif()
else()
    message(STATUS "Screenshots will be in BMP format per user request")
endif()


#this command is a workaround to some inlining issues present in older FreePascal versions and fixed in 2.6
if(FREEPASCAL_VERSION VERSION_LESS "2.6")
    #under some configurations CMAKE_BUILD_TOOL fails to pass on the jobserver, breaking parallel compilation
    if(UNIX)
        set(SAFE_BUILD_TOOL $(MAKE))
    else()
        set(SAFE_BUILD_TOOL ${CMAKE_BUILD_TOOL})
    endif()
    add_custom_target(ENGINECLEAN COMMAND ${SAFE_BUILD_TOOL} "clean" "${PROJECT_BINARY_DIR}" "${hedgewars_SOURCE_DIR}/hedgewars")
endif()


if(${FFMPEG_FOUND})
    # TODO: this check is only for SDL < 2
    # fpc will take care of linking but we need to have this library installed
    find_package(GLUT REQUIRED)

    #TODO: convert avwrapper to .pas unit so we can skip this step
    include_directories(${FFMPEG_INCLUDE_DIR})
    list(APPEND pascal_flags "-dUSE_VIDEO_RECORDING")
    if(WIN32)
        # there are some problems with linking our avwrapper as static lib, so link it as shared
        add_library(avwrapper SHARED avwrapper.c)
        target_link_libraries(avwrapper ${FFMPEG_LIBRARIES})
        install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/${CMAKE_SHARED_LIBRARY_PREFIX}avwrapper${CMAKE_SHARED_LIBRARY_SUFFIX}" DESTINATION ${target_library_install_dir})
    else()
        add_library(avwrapper STATIC avwrapper.c)
    endif()
endif()


set(fpc_flags ${pascal_flags} ${hwengine_project})

if(NOT APPLE)
    #here is the command for standard executables or for shared library
    add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}"
        COMMAND "${FREEPASCAL_EXECUTABLE}"
        ARGS ${fpc_flags} -o${engine_output_name}
        MAIN_DEPENDENCY ${hwengine_project}
        DEPENDS ${engine_sources}
        )
else()
    #these are the dependencies for building a universal binary on Mac OS X
    foreach (build_arch ${powerpc_build} ${i386_build} ${x86_64_build})
        list(APPEND lipo_args_list "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}")
        add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}"
            COMMAND "${FREEPASCAL_EXECUTABLE}"
            ARGS ${fpc_flags} -ohwengine.${build_arch} -P${build_arch}
            MAIN_DEPENDENCY ${hwengine_project}
            DEPENDS ${engine_sources}
            )
        add_custom_target(hwengine.${build_arch} ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}")
        add_custom_command(TARGET hwengine.${build_arch} POST_BUILD
            COMMAND "install_name_tool"
            ARGS -id @executable_path/../Frameworks/${engine_output_name}
                ${EXECUTABLE_OUTPUT_PATH}/hwengine.${build_arch}
            )
    endforeach()

    add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}"
        COMMAND "lipo"
        ARGS ${lipo_args_list} -create -output ${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}
        DEPENDS ${lipo_args_list}
        )
endif()


add_custom_target(hwengine ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}")

#when system Lua is not found we need to compile it before engine
if(NOT LUA_FOUND)
    add_dependencies(hwengine lua)
endif()

# same for physfs
if(NOT PHYSFS_FOUND)
    add_dependencies(hwengine physfs)
endif()

add_dependencies(hwengine physlayer)

#when ffmpeg/libav is found we need to compile it before engine
#TODO: convert avwrapper to .pas unit so we can skip this step
if(${FFMPEG_FOUND})
    add_dependencies(hwengine avwrapper)
endif()

#this command is a workaround to some inlining issues present in older FreePascal versions and fixed in 2.6
if((FREEPASCAL_VERSION VERSION_LESS "2.6") AND (NOT ${FFMPEG_FOUND}))
    add_dependencies(hwengine ENGINECLEAN)
endif()

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}" DESTINATION ${destination_dir})
