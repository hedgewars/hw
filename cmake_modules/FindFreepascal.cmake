# Load Freepascal
IF (FPC)
    SET(FPC_EXECUTABLE ${FPC})
ELSE()
    FIND_PROGRAM(FPC_EXECUTABLE
        NAMES fpc
        PATHS /opt/local/bin /usr/local/bin /usr/bin)
ENDIF()

# Check Freepascal version
IF (FPC_EXECUTABLE)
    EXEC_PROGRAM(${FPC_EXECUTABLE} ARGS "-v" OUTPUT_VARIABLE FPC_VERSION_FULL)

    STRING(REGEX MATCH "[0-9]+\\.[0-9]+" FPC_VERSION_LONG "${FPC_VERSION_FULL}")
    STRING(REGEX REPLACE "([0-9]+\\.[0-9]+)" "\\1" FPC_VERSION "${FPC_VERSION_LONG}")
ELSE()
    MESSAGE(FATAL_ERROR "Freepascal not found (required for hedgewars)")
ENDIF()
