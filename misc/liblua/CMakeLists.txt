file(GLOB lua_src *.c *.h)
set(LIBRARY_OUTPUT_PATH ${EXECUTABLE_OUTPUT_PATH})

IF(APPLE)
#	set(CMAKE_OSX_ARCHITECTURES "x86_64;i386;ppc7400")

	set(build_type STATIC)
	add_definitions(-DLUA_USE_LINUX)
	add_library (lua ${build_type} ${lua_src})
ENDIF(APPLE)

IF(WIN32)
	set(build_type SHARED)
	add_definitions(-DLUA_BUILD_AS_DLL)
	add_library (lua ${build_type} ${lua_src})
ENDIF(WIN32)

if(WIN32)
	SET_TARGET_PROPERTIES(lua PROPERTIES PREFIX "")
	install(TARGETS lua RUNTIME DESTINATION ${target_dir})
endif(WIN32)



