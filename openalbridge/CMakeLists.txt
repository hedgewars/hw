find_package(OpenAL REQUIRED)
find_package(OggVorbis REQUIRED)
include_directories(${OPENAL_INCLUDE_DIR})
include_directories(${OGGVORBIS_INCLUDE_DIRS})


set(LIBRARY_OUTPUT_PATH ${EXECUTABLE_OUTPUT_PATH})
set(openal_src
	openalwrap.c loaders.c endianness.c wrappers.c
)

#build a static library for human systems
set (build_type STATIC)


if(WIN32)
#workaround for visualstudio
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

add_library (openalbridge ${build_type} ${openal_src})

if(WIN32)
	SET_TARGET_PROPERTIES(openalbridge PROPERTIES LINK_FLAGS /DEF:openalbridge.def)
#install it in the executable directory
	install(TARGETS openalbridge DESTINATION bin)
endif(WIN32)
