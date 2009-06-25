find_package(OpenAL REQUIRED)
include_directories(${OPENAL_INCLUDE_DIR})

#add_library (openalbridge openalwrap.c loaders.c endianness.c wrappers.c)
exec_program(${CMAKE_C_COMPILER}
			ARGS ${arch_to_build} -o ${EXECUTABLE_OUTPUT_PATH}/loaders.o -c ${hedgewars_SOURCE_DIR}/openalbridge/loaders.c -I ${OPENAL_INCLUDE_DIR} -O2 -w
			OUTPUT_VARIABLE noout
)
exec_program(${CMAKE_C_COMPILER}
			ARGS ${arch_to_build} -o ${EXECUTABLE_OUTPUT_PATH}/endianness.o -c ${hedgewars_SOURCE_DIR}/openalbridge/endianness.c -I ${OPENAL_INCLUDE_DIR} -O2 -w
	OUTPUT_VARIABLE noout
)

exec_program(${CMAKE_C_COMPILER}
			ARGS ${arch_to_build} -o ${EXECUTABLE_OUTPUT_PATH}/openalwrap.o -c ${hedgewars_SOURCE_DIR}/openalbridge/openalwrap.c -I ${OPENAL_INCLUDE_DIR} -O2 -w
			OUTPUT_VARIABLE noout
)

exec_program(${CMAKE_C_COMPILER}
			ARGS ${arch_to_build} -o ${EXECUTABLE_OUTPUT_PATH}/wrappers.o -c ${hedgewars_SOURCE_DIR}/openalbridge/wrappers.c -I ${OPENAL_INCLUDE_DIR} -O2 -w
			OUTPUT_VARIABLE noout
			)
		exec_program(${CMAKE_AR}
			ARGS -rvu ${EXECUTABLE_OUTPUT_PATH}/libopenalbridge.a ${EXECUTABLE_OUTPUT_PATH}/loaders.o ${EXECUTABLE_OUTPUT_PATH}/endianness.o ${EXECUTABLE_OUTPUT_PATH}/openalwrap.o ${EXECUTABLE_OUTPUT_PATH}/wrappers.o 
			OUTPUT_VARIABLE noout
			)
		exec_program(${CMAKE_RANLIB}
			ARGS ${EXECUTABLE_OUTPUT_PATH}/libopenalbridge.a
			OUTPUT_VARIABLE noout
			)

