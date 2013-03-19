find_package(SDL)
find_package(SDL_image)
find_package(SDL_net)
find_package(SDL_ttf)
find_package(SDL_mixer)

include (CheckLibraryExists)
#Mix_Init/Mix_Quit from SDL_mixer 1.2.10
check_library_exists(${SDLMIXER_LIBRARY} Mix_Init "" HAVE_MIXINIT)
#IMG_Init/IMG_Quit from SDL_image 1.2.8
check_library_exists(${SDLIMAGE_LIBRARY} IMG_Init "" HAVE_IMGINIT)

enable_language(Pascal)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)

#SOURCE AND PROGRAMS SECTION
if(${BUILD_ENGINE_LIBRARY})
    set(engine_output_name "${CMAKE_SHARED_LIBRARY_PREFIX}hwengine${CMAKE_SHARED_LIBRARY_SUFFIX}")
    set(hwengine_project hwLibrary.pas)
else()
    set(engine_output_name "hwengine${CMAKE_EXECUTABLE_SUFFIX}")
endif()

if (APPLE)
    set(required_fpc_version 2.6)
else()
    set(required_fpc_version 2.2)
endif()

set(engine_sources
    SDLh.pas
    uSinTable.pas
    uFloat.pas
    uConsts.pas
    LuaPas.pas
    PNGh.pas
    uTypes.pas
    uUtils.pas
    uVariables.pas
    uMisc.pas
    uConsole.pas
    uDebug.pas
    uCommands.pas
    uInputHandler.pas
    uTextures.pas
    uRenderUtils.pas
    uRender.pas
    uCaptions.pas
    uLandTexture.pas
    uIO.pas
    uChat.pas
    uPhysFSLayer.pas
    uStore.pas
    uSound.pas
    uRandom.pas
    uLocale.pas
    uStats.pas
    uCursor.pas
    uVideoRec.pas
    uAILandMarks.pas
    adler32.pas
    uLandTemplates.pas
    uLandGraphics.pas
    uLandPainted.pas
    uLandOutline.pas
    uLandGenMaze.pas
    uLandObjects.pas
    uLand.pas
    uAmmos.pas

    uAIMisc.pas
    uAIActions.pas
    uAI.pas
    uWorld.pas
    uVisualGears.pas
    uTeams.pas

    uGearsList.pas
    uCollisions.pas
    uAIAmmoTests.pas
    uGears.pas
    uGame.pas
    uCommandHandlers.pas
    uGearsHandlers.pas
    uGearsHandlersRope.pas
    uGearsHedgehog.pas
    uGearsRender.pas
    uGearsUtils.pas
    uScript.pas
    hwengine.pas

    GSHandlers.inc
    VGSHandlers.inc
    ArgParsers.inc
    options.inc
    ${CMAKE_CURRENT_BINARY_DIR}/config.inc
    )


include(${CMAKE_MODULE_PATH}/utils.cmake)

find_package_or_fail(FreePascal)

#when cmake-2.6 support is dropped, this ought to be inside FindFreePascal.cmake
if (FREEPASCAL_VERSION VERSION_LESS required_fpc_version)
    message(FATAL_ERROR "Freepascal ${FREEPASCAL_VERSION} is too old, minimum version required is ${required_fpc_version}")
elseif(FREEPASCAL_VERSION VERSION_GREATER 2.4)
    #enable INLINE only with a recent version of fpc
    add_flag_append(CMAKE_Pascal_FLAGS_RELEASE -Si)
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
        add_subdirectory(sdlmain)
        add_flag_append(CMAKE_Pascal_FLAGS -Fl${LIBRARY_OUTPUT_PATH})
    endif()
endif(APPLE)

if(FFMPEG_FOUND)
    add_subdirectory(avwrapper)
    add_definitions(-dUSE_VIDEO_RECORDING)
    add_flag_append(CMAKE_Pascal_FLAGS -Fl${LIBRARY_OUTPUT_PATH})
endif()

find_package_or_disable_msg(PNG NOPNG "Screenshots will be saved in BMP")
if(PNG_FOUND)
    get_filename_component(PNG_LIB_DIR ${PNG_LIBRARY} PATH)
    add_definitions(-dPNG_SCREENSHOTS)
    add_flag_append(CMAKE_Pascal_FLAGS -Fl${PNG_LIB_DIR})
endif()

if(NOT LUA_FOUND)
    add_flag_append(CMAKE_Pascal_FLAGS -k${EXECUTABLE_OUTPUT_PATH}/lib${LUA_LIBRARY}.a)
    #linking with liblua.a requires system readline
    if(UNIX)
        add_flag_append(CMAKE_Pascal_FLAGS -k-lreadline)
    endif(UNIX)
endif()

if(NOT PHYSFS_FOUND)
    #-XLA is a beta fpc flag that renames libraries before passing them to the linker
    #we also have to pass PHYSFS_INTERNAL to satisfy windows runtime requirements
    #(should be harmless on other platforms)
    add_flag_append(CMAKE_Pascal_FLAGS "-XLAphysfs=${physfs_output_name}")
    add_definitions(-dPHYSFS_INTERNAL)
endif()

if(APPLE)
    add_flag_append(CMAKE_Pascal_FLAGS -Px86_64)
else()
    add_flag_append(CMAKE_Pascal_FLAGS -Pi386)
endif()


if(BUILD_ENGINE_LIBRARY)
    message(${WARNING} "Engine will be built as library (experimental)")
    add_definitions(-dHWLIBRARY)

    # due to compiler/linker issues on Max OS X 10.6 -k-no_order_inits is needed to avoid linking fail
    if(APPLE AND current_macosx_version VERSION_GREATER "10.5")
        add_flag_append(CMAKE_Pascal_FLAGS "-k-no_order_inits")
    endif()
    set(destination_dir ${target_library_install_dir})
else(BUILD_ENGINE_LIBRARY)
    set(destination_dir ${target_binary_install_dir})
endif(BUILD_ENGINE_LIBRARY)


if(HAVE_MIXINIT)
    add_definitions(-dSDL_MIXER_NEWER)
endif(HAVE_MIXINIT)

if(HAVE_IMGINIT)
    add_definitions(-dSDL_IMAGE_NEWER)
endif(HAVE_IMGINIT)

add_definitions(-dDEBUGFILE)
add_executable(hwengine ${engine_sources})

#when system Lua is not found we need to compile it before engine
if(NOT LUA_FOUND)
    target_link_libraries(hwengine lua)
endif()

# same for physfs
if(NOT PHYSFS_FOUND)
    target_link_libraries(hwengine physfs)
endif()

target_link_libraries(hwengine physlayer)

#when ffmpeg/libav is found we need to compile it before engine
#TODO: convert avwrapper to .pas unit so we can skip this step
if(${FFMPEG_FOUND})
    target_link_libraries(hwengine avwrapper)
endif()

if(APPLE)
    target_link_libraries(hwengine SDLmain)
endif()

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}" DESTINATION ${destination_dir})
