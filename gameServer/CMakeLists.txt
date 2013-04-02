
include(${CMAKE_MODULE_PATH}/utils.cmake)

find_package_or_disable(GHC NOSERVER)

set(hwserver_sources
    OfficialServer/DBInteraction.hs
    Actions.hs
    ClientIO.hs
    ConfigFile.hs
    Consts.hs
    CoreTypes.hs
    EngineInteraction.hs
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

set(hwserv_main ${CMAKE_SOURCE_DIR}/gameServer/hedgewars-server.hs)

set(ghc_flags
    --make ${hwserv_main}
    -i${CMAKE_CURRENT_SOURCE_DIR}
    -o ${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}
    -odir ${CMAKE_CURRENT_BINARY_DIR}
    -hidir ${CMAKE_CURRENT_BINARY_DIR}
    ${haskell_flags})

add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}"
        COMMAND "${GHC_EXECUTABLE}"
        ARGS ${ghc_flags}
        MAIN_DEPENDENCY ${hwserv_main}
        DEPENDS ${hwserver_sources}
        )

add_custom_target(hedgewars-server ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_binary_install_dir})
