IF(APPLE)
	file(GLOB lua_src *.c *.h) 
	set(CMAKE_OSX_ARCHITECTURES "x86_64;i386;ppc7400")	
	
	set (build_type STATIC)
	add_definitions(-DLUA_USE_LINUX)
	add_library (lua ${build_type} ${lua_src})
ENDIF(APPLE)
