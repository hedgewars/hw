find_program(ghc_executable ghc)

if(NOT ghc_executable)
    message(FATAL_ERROR "Cannot find GHC")
endif(NOT ghc_executable)


set(hwserver_sources
    OfficialServer/DBInteraction.hs
    Actions.hs
    ClientIO.hs
    CoreTypes.hs
    HWProtoCore.hs
    HWProtoInRoomState.hs
    HWProtoLobbyState.hs
    HWProtoNEState.hs
    HandlerUtils.hs
    NetRoutines.hs
    Opts.hs
    RoomsAndClients.hs
    ServerCore.hs
    ServerState.hs
    Store.hs
    Utils.hs
    hedgewars-server.hs
    )

set(hwserv_main ${hedgewars_SOURCE_DIR}/gameServer/hedgewars-server.hs)

set(ghc_flags
    -Wall
    --make ${hwserv_main}
    -i${hedgewars_SOURCE_DIR}/gameServer
    -o ${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}
    -odir ${CMAKE_CURRENT_BINARY_DIR}
    -hidir ${CMAKE_CURRENT_BINARY_DIR})

set(ghc_flags ${haskell_compiler_flags_cmn} ${ghc_flags})

add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}"
        COMMAND "${ghc_executable}"
        ARGS ${ghc_flags}
        MAIN_DEPENDENCY ${hwserv_main}
        DEPENDS ${hwserver_sources}
        )

add_custom_target(hedgewars-server ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_dir})
