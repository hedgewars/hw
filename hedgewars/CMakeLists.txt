enable_language(Pascal)

find_package(SDL2 REQUIRED)
find_package(SDL2_image REQUIRED)
find_package(SDL2_net REQUIRED)
find_package(SDL2_ttf REQUIRED)
find_package(SDL2_mixer REQUIRED)

include (CheckLibraryExists)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)
include_directories(${CMAKE_CURRENT_BINARY_DIR})


#set the sources with the correct order of dependencies so that cmake won't be confused
set(engine_sources
    SDLh.pas
    uSinTable.pas
    uFloat.pas
    uConsts.pas
    LuaPas.pas
    uTypes.pas
    uVariables.pas
    uUtils.pas
    uMisc.pas
    uConsole.pas
    uCommands.pas
    uDebug.pas
    uInputHandler.pas
    uTextures.pas
    uRenderUtils.pas
    uRender.pas
    uCaptions.pas
    uIO.pas
    uChat.pas
    uPhysFSLayer.pas
    uSound.pas
    ArgParsers.pas
    uRandom.pas
    uLocale.pas
    uStats.pas
    uCursor.pas
    uVideoRec.pas
    uAILandMarks.pas
    adler32.pas
    uLandTemplates.pas
    uLandTexture.pas
    uLandGraphics.pas
    uLandPainted.pas
    uLandOutline.pas
    uLandGenMaze.pas

    #this is where dependency tracking becomes hard
    uStore.pas
    uAmmos.pas
    uLandObjects.pas
    uLand.pas
    uGearsList.pas
    uCollisions.pas
    uAIMisc.pas
    uAIActions.pas
    uAIAmmoTests.pas
    uAI.pas
    uWorld.pas
    uVisualGearsList.pas
    uVisualGearsHandlers.pas
    uVisualGears.pas

    uGears.pas
    uGame.pas
    uCommandHandlers.pas
    uGearsRender.pas
    uGearsHedgehog.pas
    uGearsHandlers.pas
    uGearsHandlersRope.pas
    uGearsHandlersMess.pas
    uGearsUtils.pas
    uTeams.pas

    #these interact with everything, so compile last
    uScript.pas
    hwengine.pas

    #we also have uTouch.pas
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


if(FFMPEG_FOUND)
    add_subdirectory(avwrapper)
    list(APPEND HW_LINK_LIBS avwrapper)
    add_definitions(-dUSE_VIDEO_RECORDING)
    add_flag_append(CMAKE_Pascal_FLAGS -Fl${LIBRARY_OUTPUT_PATH})
    
endif()

find_package_or_disable_msg(PNG NOPNG "Screenshots will be saved in BMP")
if(PNG_FOUND)
    list(INSERT engine_sources 0 PNGh.pas)
    list(REMOVE_AT PNG_LIBRARIES 1) #removing the zlib library path
    get_filename_component(PNG_LIBRARY_DIR ${PNG_LIBRARIES} PATH)
    add_flag_append(CMAKE_Pascal_FLAGS -Fl${PNG_LIBRARY_DIR})
    add_definitions(-dPNG_SCREENSHOTS)
endif()

if(LUA_FOUND AND LUA_SYSTEM)
    get_filename_component(LUA_LIBRARY_DIR ${LUA_LIBRARY} PATH)
    get_filename_component(LUA_LIBRARY_NAME ${LUA_LIBRARY} NAME)
    #NAME_WE would strip the .1 (or .2) next to the ".so"
    string(REGEX REPLACE "${CMAKE_SHARED_LIBRARY_PREFIX}(.*)${CMAKE_SHARED_LIBRARY_SUFFIX}" "\\1" LUA_LIBRARY_NAME "${LUA_LIBRARY_NAME}")
    add_flag_append(CMAKE_Pascal_FLAGS "-Fl${LUA_LIBRARY_DIR} -XLAlua=${LUA_LIBRARY_NAME}")
else()
    add_definitions(-dLUA_INTERNAL)
    list(APPEND HW_LINK_LIBS lua)
    add_flag_append(CMAKE_Pascal_FLAGS "-XLAlua=${lua_output_name}")
endif()


if(NOT PHYSFS_FOUND)
    add_definitions(-dPHYSFS_INTERNAL)
    list(APPEND HW_LINK_LIBS physfs)
    #-XLA is a beta fpc flag that renames libraries before passing them to the linker
    #we also have to pass PHYSFS_INTERNAL to satisfy windows runtime requirements
    #(should be harmless on other platforms)
    add_flag_append(CMAKE_Pascal_FLAGS "-Fl${LIBRARY_OUTPUT_PATH} -XLAphysfs=${physfs_output_name}")
endif()
list(APPEND HW_LINK_LIBS physlayer)

#Mix_Init/Mix_Quit from SDL_mixer 1.2.10

#needs to be last
add_definitions(-dDEBUGFILE)


# make source files objects depend on their predecessors in list
set(sourcefiles_sofar "${CMAKE_CURRENT_SOURCE_DIR}/options.inc" "${CMAKE_CURRENT_BINARY_DIR}/config.inc")
foreach(loop_var ${engine_sources})
    SET_SOURCE_FILES_PROPERTIES(${loop_var} PROPERTIES OBJECT_DEPENDS "${sourcefiles_sofar}")
    list(APPEND sourcefiles_sofar "${CMAKE_CURRENT_SOURCE_DIR}/${loop_var}")
endforeach(loop_var)


#SOURCE AND PROGRAMS SECTION
if(BUILD_ENGINE_LIBRARY)
    message("***Engine will be built as library (experimental)***")
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
