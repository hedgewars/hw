find_program(ghc_executable ghc)

if (NOT ghc_executable)
	message("Cannot find GHC" FATAL)
endif(NOT ghc_executable)

set(hwserver_sources
	HWProto.hs
	Miscutils.hs
	Opts.hs
	hedgewars-server.hs
	)

set(ghc_flags "--make" "hedgewars-server.hs")

add_custom_command(OUTPUT "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}"
		COMMAND "${ghc_executable}"
		ARGS ${ghc_flags}
		MAIN_DEPENDENCY "hedgewars-server.hs"
		DEPENDS ${hwserver_sources}
		)

add_custom_target(hedgewars-server ALL DEPENDS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}")

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars-server${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION bin)
