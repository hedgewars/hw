set(pas2c_sources
    Main.hs
    PascalBasics.hs
    PascalParser.hs
    PascalPreprocessor.hs
    PascalUnitSyntaxTree.hs
    pas2c.hs
        )

set(pas2c_main ${hedgewars_SOURCE_DIR}/tools/pas2c/Main.hs)

set(ghc_flags
    --make ${pas2c_main}
    -i${hedgewars_SOURCE_DIR}/tools/pas2c/
    -o ${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}
    -odir ${CMAKE_CURRENT_BINARY_DIR}
    -hidir ${CMAKE_CURRENT_BINARY_DIR}
    ${haskell_flags})

add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}"
        COMMAND "${ghc_executable}"
        ARGS ${ghc_flags}
        MAIN_DEPENDENCY ${hwserv_main}
        DEPENDS ${hwserver_sources}
        )

add_custom_target(pas2c ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/pas2c${CMAKE_EXECUTABLE_SUFFIX}")

