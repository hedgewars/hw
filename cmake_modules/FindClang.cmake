# Load LLVM/Clang
IF (CLANG)
    SET(CLANG_EXECUTABLE ${CLANG})
ELSE()
    FIND_PROGRAM(CLANG_EXECUTABLE
        NAMES clang-mp-3.2 clang-mp-3.1 clang-mp-3.0 clang
        PATHS /opt/local/bin /usr/local/bin /usr/bin)
ENDIF()

# Check LLVM/Clang version
IF (CLANG_EXECUTABLE)
    EXEC_PROGRAM(${CLANG_EXECUTABLE} ARGS "-v" OUTPUT_VARIABLE CLANG_VERSION_FULL)

    STRING(REGEX MATCH "[0-9]+\\.[0-9]+" CLANG_VERSION_LONG "${CLANG_VERSION_FULL}")
    STRING(REGEX REPLACE "([0-9]+\\.[0-9]+)" "\\1" CLANG_VERSION "${CLANG_VERSION_LONG}")
ELSE()
    MESSAGE(FATAL_ERROR "No LLVM/Clang compiler found (required for engine_c target)")
ENDIF()

SET(CMAKE_C_COMPILER ${CLANG_EXECUTABLE})
