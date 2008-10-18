find_program(ghc_executable ghc)

if (NOT ghc_executable)
	message(FATAL_ERROR "Cannot find GHC")
endif(NOT ghc_executable)

set(hwserver_sources
	HWProto.hs
	Miscutils.hs
	Opts.hs
	hedgewars-server.hs
	)

set(hwserv_main ${hedgewars_SOURCE_DIR}/netserver/hedgewars-server.hs)

set(ghc_flags
	--make ${hwserv_main}
	-i${hedgewars_SOURCE_DIR}/netserver
	-o ${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}
	-odir ${CMAKE_CURRENT_BINARY_DIR}
	-hidir ${CMAKE_CURRENT_BINARY_DIR})

add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}"
		COMMAND "${ghc_executable}"
		ARGS ${ghc_flags}
		MAIN_DEPENDENCY ${hwserv_main}
		DEPENDS ${hwserver_sources}
		)

add_custom_target(hedgewars-server ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION bin)
