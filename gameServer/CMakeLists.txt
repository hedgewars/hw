
include(${CMAKE_MODULE_PATH}/utils.cmake)

find_package_or_disable(GHC NOSERVER)

include(${CMAKE_MODULE_PATH}/CheckHaskellModuleExists.cmake)

check_haskell_module_exists("Control.Exception" mask 1 base)
check_haskell_module_exists("Data.Map" size 1 containers)
check_haskell_module_exists("Data.Vector" length 1 vector)
check_haskell_module_exists("Data.ByteString" pack 1 bytestring)
check_haskell_module_exists("Network.BSD" getHostName 0 network)
check_haskell_module_exists("Data.Time" getCurrentTime 0 time)
check_haskell_module_exists("Control.Monad.State" fix 1 mtl)
check_haskell_module_exists("Codec.Binary.Base64" encode 1 sandi)
check_haskell_module_exists("System.Log.Logger" warningM 1 hslogger)
check_haskell_module_exists("System.Process" createProcess 3 process)
check_haskell_module_exists("Data.ByteString.Lazy.UTF8" decode 1 utf8-string)
check_haskell_module_exists("Data.Digest.Pure.SHA" sha1 1 SHA)
check_haskell_module_exists("System.Entropy" openHandle 0 entropy)
check_haskell_module_exists("Codec.Compression.Zlib" decompress 1 zlib)
check_haskell_module_exists("System.Random" getStdGen 0 random)
check_haskell_module_exists("Text.Regex.TDFA.ByteString" execute 2 regex-tdfa)

# this one needs type signatures to work
# check_haskell_module_exists("Control.DeepSeq" deepseq 2 deepseq)



set(hwserver_sources
    OfficialServer/DBInteraction.hs
    Actions.hs
    ClientIO.hs
    ConfigFile.hs
    Consts.hs
    CoreTypes.hs
    EngineInteraction.hs
    FloodDetection.hs
    HWProtoCore.hs
    HWProtoInRoomState.hs
    HWProtoLobbyState.hs
    HWProtoNEState.hs
    HandlerUtils.hs
    JoinsMonitor.hs
    NetRoutines.hs
    Opts.hs
    RoomsAndClients.hs
    ServerCore.hs
    ServerState.hs
    Store.hs
    Utils.hs
    Votes.hs
    hedgewars-server.hs
    )

set(hwserv_main ${CMAKE_CURRENT_SOURCE_DIR}/hedgewars-server.hs)

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
