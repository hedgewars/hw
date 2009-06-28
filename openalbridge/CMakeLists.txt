find_package(OpenAL REQUIRED)
find_package(OggVorbis REQUIRED)
include_directories(${OPENAL_INCLUDE_DIR})
include_directories(${OGGVORBIS_INCLUDE_DIRS})

#set flag configuration for build type
set(CMAKE_C_FLAGS "-Wall -pipe")
set(CMAKE_C_FLAGS_RELEASE "-w -O2 -fomit-frame-pointer")
set(CMAKE_C_FLAGS_DEBUG "-O0 -g -DDEBUG")

#set destination directory for library
set(LIBRARY_OUTPUT_PATH ${EXECUTABLE_OUTPUT_PATH})

#list of source files for libraries
set(openal_src
	openalwrap.c loaders.c endianness.c wrappers.c
)

#build a static library for human systems
set (build_type STATIC)

if(WIN32)
#workaround for visualstudio (wants headers in the source list)
	set(openal_src
		openalwrap.h loaders.h endianness.h wrappers.h winstdint.h ${openal_src}
	)
#deps for the shared library
	link_libraries(${OPENAL_LIBRARY})
	link_libraries(${OGG_LIBRARY})
	link_libraries(${VORBIS_LIBRARY})
	link_libraries(${VORBISFILE_LIBRARY})
#build a shared library
	set (build_type SHARED)
endif(WIN32)

#compiles and links actual library
add_library (openalbridge ${build_type} ${openal_src})

if(WIN32)
	SET_TARGET_PROPERTIES(openalbridge PROPERTIES LINK_FLAGS /DEF:openalbridge.def)
#install it in the executable directory
	install(TARGETS openalbridge DESTINATION bin)
endif(WIN32)
