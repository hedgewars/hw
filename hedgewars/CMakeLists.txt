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
include_directories(${CMAKE_CURRENT_BINARY_DIR})


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

if (${CMAKE_Pascal_COMPILER_VERSION} VERSION_LESS 2.2 OR # older versions are just ancient
    (${CMAKE_Pascal_COMPILER_VERSION} VERSION_LESS 2.6 AND APPLE)) # because of 64bit and opengl bindings
    message(FATAL_ERROR "Your FreePascal installation is too old (fpc ${CMAKE_Pascal_COMPILER_VERSION})!")
elseif(CMAKE_Pascal_COMPILER_VERSION VERSION_GREATER 2.4)
    #enable INLINE only with a recent version of fpc
    add_flag_prepend(CMAKE_Pascal_FLAGS_RELEASE -Si)
endif()


#DEPENDECIES AND EXECUTABLES SECTION
if(APPLE)
    if(CMAKE_OSX_ARCHITECTURES)
        #parse this system variable and adjust only the powerpc syntax to be compatible with -P
        string(REGEX MATCH "[pP][pP][cC]+" powerpc_build "${CMAKE_OSX_ARCHITECTURES}")
        string(REGEX MATCH "[iI]386+" i386_build "${CMAKE_OSX_ARCHITECTURES}")
        string(REGEX MATCH "[xX]86_64+" x86_64_build "${CMAKE_OSX_ARCHITECTURES}")
        if(x86_64_build)
            add_flag_prepend(CMAKE_Pascal_FLAGS -Px86_64)
        elseif(i386_build)
            add_flag_prepend(CMAKE_Pascal_FLAGS -Pi386)
        elseif(powerpc_build)
            add_flag_prepend(CMAKE_Pascal_FLAGS -Ppowerpc)
        else()
            message(FATAL_ERROR "Unknown architecture present in CMAKE_OSX_ARCHITECTURES (${CMAKE_OSX_ARCHITECTURES})")
        endif()
        list(LENGTH CMAKE_OSX_ARCHITECTURES num_of_archs)
        if(num_of_archs GREATER 1)
            message(${WARNING} "Only one architecture in CMAKE_OSX_ARCHITECTURES is currently supported, picking the first one")
        endif()
    elseif(CMAKE_SIZEOF_VOID_P MATCHES "8")
        #if that variable is not set check if we are on x86_64 and if so force it, else use default
        add_flag_prepend(CMAKE_Pascal_FLAGS -Px86_64)
    endif()

    #on OSX we need to provide the SDL_main() function when building as executable
    if(NOT BUILD_ENGINE_LIBRARY)
        add_subdirectory(sdlmain)
        list(APPEND HW_LINK_LIBS SDLmain)
        add_flag_append(CMAKE_Pascal_FLAGS -Fl${LIBRARY_OUTPUT_PATH})
    endif()
endif(APPLE)

if(FFMPEG_FOUND)
    add_subdirectory(avwrapper)
    list(APPEND HW_LINK_LIBS avwrapper)
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
    list(APPEND HW_LINK_LIBS lua)
    add_flag_append(CMAKE_Pascal_FLAGS -k${EXECUTABLE_OUTPUT_PATH}/lib${LUA_LIBRARY}.a)
    #linking with liblua.a requires system readline
    if(UNIX)
        add_flag_append(CMAKE_Pascal_FLAGS -k-lreadline)
    endif(UNIX)
endif()

if(NOT PHYSFS_FOUND)
    add_definitions(-dPHYSFS_INTERNAL)
    list(APPEND HW_LINK_LIBS physfs)
    #-XLA is a beta fpc flag that renames libraries before passing them to the linker
    #we also have to pass PHYSFS_INTERNAL to satisfy windows runtime requirements
    #(should be harmless on other platforms)
    add_flag_append(CMAKE_Pascal_FLAGS "-XLAphysfs=${physfs_output_name}")
endif()
list(APPEND HW_LINK_LIBS physlayer)

if(HAVE_MIXINIT)
    add_definitions(-dSDL_MIXER_NEWER)
endif(HAVE_MIXINIT)

if(HAVE_IMGINIT)
    add_definitions(-dSDL_IMAGE_NEWER)
endif(HAVE_IMGINIT)

add_definitions(-dDEBUGFILE)

#SOURCE AND PROGRAMS SECTION
if(BUILD_ENGINE_LIBRARY)
    message(${WARNING} "Engine will be built as library (experimental)")
    if(APPLE AND current_macosx_version VERSION_GREATER "10.5")
        # due to compiler/linker issues on Max OS X 10.6 -k-no_order_inits is needed to avoid linking fail
        add_flag_prepend(CMAKE_Pascal_FLAGS "-k-no_order_inits")
    endif()

    #workaround for missing <TARGET> support during object generation
    set(engine_output_name "${CMAKE_SHARED_LIBRARY_PREFIX}hwengine${CMAKE_SHARED_LIBRARY_SUFFIX}")
    set(destination_dir ${target_library_install_dir})
    add_flag_prepend(CMAKE_Pascal_FLAGS "-o${LIBRARY_OUTPUT_PATH}/${engine_output_name}")

    add_definitions(-dHWLIBRARY)
    add_library(hwengine SHARED ${engine_sources} hwLibrary.pas)
else()
    # no need to change name here because target has same name
    set(engine_output_name "hwengine${CMAKE_EXECUTABLE_SUFFIX}")
    set(destination_dir ${target_binary_install_dir})
    add_executable(hwengine ${engine_sources})
endif()

#even though not actually used, this will trigger relink if any lib changes
target_link_libraries(hwengine ${HW_LINK_LIBS})

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/${engine_output_name}" DESTINATION ${destination_dir})
