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
    message(STATUS "Found Freepascal: ${FPC_EXECUTABLE} (version ${FPC_VERSION}")
else()
    message(FATAL_ERROR "Could NOT find Freepascal")
endif()

# Check for noexecstack flag support
message(STATUS "Checking whether linker needs explicit noexecstack")
set(NOEXECSTACK_FLAGS "-k-z" "-knoexecstack")
file(WRITE ${EXECUTABLE_OUTPUT_PATH}/checkstack.pas "begin end.")

execute_process(COMMAND ${FPC_EXECUTABLE} ${NOEXECSTACK_FLAGS} checkstack.pas
    WORKING_DIRECTORY ${EXECUTABLE_OUTPUT_PATH}
    RESULT_VARIABLE TEST_NOEXECSTACK
    OUTPUT_QUIET ERROR_QUIET)

if (TEST_NOEXECSTACK)
    set(NOEXECSTACK_FLAGS "")
    message(STATUS "Checking whether linker needs explicit noexecstack -- no")
else(TEST_NOEXECSTACK)
    message(STATUS "Checking whether linker needs explicit noexecstack -- yes")
endif(TEST_NOEXECSTACK)

