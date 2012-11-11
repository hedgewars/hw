
if(CLANG)
    set(clang_executable ${CLANG})
else()
    find_program(clang_executable
        NAMES clang-mp-3.2 clang-mp-3.1 clang-mp-3.0 clang
        PATHS /opt/local/bin /usr/local/bin /usr/bin)
endif()

if (clang_executable)
    exec_program(${clang_executable} ARGS "-v" OUTPUT_VARIABLE clang_version_full)
    string(REGEX MATCH "[0-9]+\\.[0-9]+" clang_version_long "${clang_version_full}")
    string(REGEX REPLACE "([0-9]+\\.[0-9]+)" "\\1" clang_version "${clang_version_long}")
    #TODO: check version >= 3.0
    message(STATUS "Found CLANG: ${clang_executable} (version ${clang_version})")
else()
    message(FATAL_ERROR "No LLVM/Clang compiler found (required for engine_c target)")
endif()

set(CMAKE_C_COMPILER ${clang_executable})


find_package(GLEW REQUIRED)


configure_file(${hedgewars_SOURCE_DIR}/hedgewars/config.inc.in ${CMAKE_CURRENT_BINARY_DIR}/config.inc)


add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/hwengine.c"
        COMMAND "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}"
        ARGS -n hwengine
             -i "${hedgewars_SOURCE_DIR}/hedgewars"
             #-i "~/xymengxy-webport/hedgewars"
             -o "${CMAKE_CURRENT_BINARY_DIR}"
             -a "${CMAKE_CURRENT_BINARY_DIR}"
        DEPENDS pas2c
    )

add_custom_target(engine_c ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/hwengine.c")


add_subdirectory(rtl)

include_directories("${GLEW_INCLUDE_PATH}")
include_directories(rtl)

set(engine_src               uDebug.c             uLandTexture.c
        LuaPas.c             uFloat.c             uLocale.c
        SDLh.c               uGame.c              uMisc.c
        adler32.c            uGears.c             uMobile.c
        hwengine.c           uGearsHandlers.c     uRandom.c
        uAI.c                uGearsHandlersRope.c uRender.c
        uAIActions.c         uGearsHedgehog.c     uRenderUtils.c
        uAIAmmoTests.c       uGearsList.c         uScript.c
        uAILandMarks.c       uGearsRender.c       uSinTable.c
        uAIMisc.c            uGearsUtils.c        uSound.c
        uAmmos.c             uIO.c                uStats.c
        uCaptions.c          uInputHandler.c      uStore.c
        uChat.c              uLand.c              uTeams.c
        uCollisions.c        uLandGenMaze.c       uTextures.c
        uCommandHandlers.c   uLandGraphics.c      uTypes.c
        uCommands.c          uLandObjects.c       uUtils.c
        uConsole.c           uLandOutline.c       uVariables.c
        uConsts.c            uLandPainted.c       uVisualGears.c
        uCursor.c            uLandTemplates.c     uWorld.c
    )

set(engine_hdr               uGame.h              uFloat.h
        uLocale.h            SDLh.h               uMisc.h
        adler32.h            uDebug.h             uLandTexture.h
        LuaPas.h             uGears.h             uMobile.h
        uAI.h                uGearsHandlersRope.h uRender.h
        uAIActions.h         uGearsHedgehog.h     uRenderUtils.h
        uAIAmmoTests.h       uGearsList.h         uScript.h
        uGearsHandlers.h     uRandom.h
        uAILandMarks.h       uGearsRender.h       uSinTable.h
        uAIMisc.h            uGearsUtils.h        uSound.h
        uAmmos.h             uIO.h                uStats.h
        uCaptions.h          uInputHandler.h      uStore.h
        uChat.h              uLand.h              uTeams.h
        uCollisions.h        uLandGenMaze.h       uTextures.h
        uCommandHandlers.h   uLandGraphics.h      uTypes.h
        uCommands.h          uLandObjects.h       uUtils.h
        uConsole.h           uLandOutline.h       uVariables.h
        uConsts.h            uLandPainted.h       uVisualGears.h
        uCursor.h            uLandTemplates.h     uWorld.h
    )

add_executable(hwengine WIN32 ${engine_src})
add_dependencies(hwengine engine_c fpcrtl)

