# Load Freepascal
if (FPC)
    set(FPC_EXECUTABLE ${FPC})
else()
    find_program(FPC_EXECUTABLE
        NAMES fpc
        PATHS /opt/local/bin /usr/local/bin /usr/bin)
endif()

# Check Freepascal version
if (FPC_EXECUTABLE)
    exec_program(${FPC_EXECUTABLE} ARGS "-v" OUTPUT_VARIABLE FPC_VERSION_FULL)

    string(REGEX MATCH "[0-9]+\\.[0-9]+" FPC_VERSION_LONG "${FPC_VERSION_FULL}")
    string(REGEX REPLACE "([0-9]+\\.[0-9]+)" "\\1" FPC_VERSION "${FPC_VERSION_LONG}")
else()
    message(FATAL_ERROR "Freepascal not found (required for hedgewars)")
endif()

# Check for noexecstack flag support
set(NOEXECSTACK_FLAGS "-k-z" "-knoexecstack")
file(WRITE ${EXECUTABLE_OUTPUT_PATH}/checkstack.pas "begin end.")

execute_process(COMMAND ${FPC_EXECUTABLE} ${NOEXECSTACK_FLAGS} checkstack.pas
    WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
    RESULT_VARIABLE TEST_NOEXECSTACK
    OUTPUT_QUIET ERROR_QUIET)

if (TEST_NOEXECSTACK)
    set(NOEXECSTACK_FLAGS "")
    message(STATUS "Checking whether linker needs explicit noexecstack -- no")
else()
    message(STATUS "Checking whether linker needs explicit noexecstack -- yes")
endif()
