find_package(OpenAL REQUIRED)
find_package(OggVorbis REQUIRED)
include_directories(${OPENAL_INCLUDE_DIR})
include_directories(${OGGVORBIS_INCLUDE_DIRS})

#set destination directory for library
set(LIBRARY_OUTPUT_PATH ${EXECUTABLE_OUTPUT_PATH})

#list of source files for libraries
set(openal_src
	openalbridge.c loaders.c wrappers.c errlib.c
)

#build a static library for human systems
set (build_type STATIC)

#visualstudio and windows in general don't like static linking, so we're building the library in shared mode
if(WIN32)
#workaround for visualstudio (wants headers in the source list)
	set(openal_src
		openalbridge.h openalbridge_t.h loaders.h wrappers.h globals.h oggvorbis.h errlib.h ${openal_src}
	)
#deps for the shared library
	link_libraries(${VORBISFILE_LIBRARY})
	link_libraries(${VORBIS_LIBRARY})
	link_libraries(${OGG_LIBRARY})
	link_libraries(${OPENAL_LIBRARY})
#build a shared library
	set (build_type SHARED)
endif()

#compiles and links actual library
add_library (openalbridge ${build_type} ${openal_src})

if(WIN32)
if(MSVC)
	SET_TARGET_PROPERTIES(openalbridge PROPERTIES LINK_FLAGS /DEF:openalbridge.def)
endif(MSVC)
#install it in the executable directory
	install(TARGETS openalbridge DESTINATION bin)
endif(WIN32)
