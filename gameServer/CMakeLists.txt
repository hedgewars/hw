cmake_minimum_required(VERSION 3.12.0)
project(hedgewars-server)

if(NOT DEFINED CMAKE_MODULE_PATH)
 set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/server_cmake_modules")
endif()

include(${CMAKE_MODULE_PATH}/utils.cmake)

find_package_or_disable(GHC NOSERVER)

include(${CMAKE_MODULE_PATH}/CheckHaskellPackageExists.cmake)

message("CMP_PATH":${CMAKE_MODULE_PATH})

check_haskell_package_exists(base "Control.Exception" mask 1 REQUIRED)
check_haskell_package_exists(containers "Data.Map" size 1 REQUIRED)
check_haskell_package_exists(vector "Data.Vector" length 1 REQUIRED)
check_haskell_package_exists(bytestring "Data.ByteString" pack 1 REQUIRED)
check_haskell_package_exists(network "Network.Socket" defaultHints 0 REQUIRED)
check_haskell_package_exists(network-bsd "Network.BSD" getHostName 0 OPTIONAL)
check_haskell_package_exists(time "Data.Time" getCurrentTime 0 REQUIRED)
check_haskell_package_exists(mtl "Control.Monad.State" fix 1 REQUIRED)
check_haskell_package_exists(sandi "Codec.Binary.Base64" encode 1 REQUIRED)
check_haskell_package_exists(hslogger "System.Log.Logger" warningM 1 REQUIRED)
check_haskell_package_exists(process "System.Process" createProcess 3 REQUIRED)
check_haskell_package_exists(utf8-string "Data.ByteString.Lazy.UTF8" decode 1 REQUIRED)
check_haskell_package_exists(SHA "Data.Digest.Pure.SHA" sha1 1 REQUIRED)
check_haskell_package_exists(entropy "System.Entropy" openHandle 0 REQUIRED)
check_haskell_package_exists(zlib "Codec.Compression.Zlib" decompress 1 REQUIRED)
check_haskell_package_exists(random "System.Random" getStdGen 0 REQUIRED)
check_haskell_package_exists(regex-tdfa "Text.Regex.TDFA.ByteString" execute 2 REQUIRED)
check_haskell_package_exists(deepseq "Control.DeepSeq" deepseq 2 REQUIRED)



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

set(ghc_flags -dynamic
    --make ${hwserv_main}
    -i${CMAKE_CURRENT_SOURCE_DIR}
    -o ${CMAKE_CURRENT_BINARY_DIR}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}
    -odir ${CMAKE_CURRENT_BINARY_DIR}
    -hidir ${CMAKE_CURRENT_BINARY_DIR}
    ${haskell_flags})

add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}"
        COMMAND "${GHC_EXECUTABLE}"
        ARGS ${ghc_flags}
        MAIN_DEPENDENCY ${hwserv_main}
        DEPENDS ${hwserver_sources}
        )

add_custom_target(hedgewars-server ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION "bin")
