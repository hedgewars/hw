# Load LLVM/Clang
if (CLANG)
    set(CLANG_EXECUTABLE ${CLANG})
else()
    find_program(CLANG_EXECUTABLE
        NAMES clang-mp-3.3 clang-mp-3.2 clang-mp-3.1 clang-mp-3.0 clang
        PATHS /opt/local/bin /usr/local/bin /usr/bin)
endif()

# Check LLVM/Clang version
if (CLANG_EXECUTABLE)
    exec_program(${CLANG_EXECUTABLE} ARGS "-v" OUTPUT_VARIABLE CLANG_VERSION_FULL)

    string(REGEX MATCH "[0-9]+\\.[0-9]+" CLANG_VERSION_LONG "${CLANG_VERSION_FULL}")
    string(REGEX REPLACE "([0-9]+\\.[0-9]+)" "\\1" CLANG_VERSION "${CLANG_VERSION_LONG}")
else()
    message(FATAL_ERROR "No LLVM/Clang compiler found (required for engine_c target)")
endif()

set(CMAKE_C_COMPILER ${CLANG_EXECUTABLE})
set(CMAKE_CXX_COMPILER ${CLANG_EXECUTABLE})
