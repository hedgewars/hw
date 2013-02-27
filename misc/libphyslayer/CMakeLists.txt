
find_package(SDL REQUIRED)
include_directories(${PHYSFS_INCLUDE_DIR})
include_directories(${SDL_INCLUDE_DIR})
include_directories(${LUA_INCLUDE_DIR})

## extra functions needed by Hedgewars
## TODO: maybe it's better to have them in a separate library?
set(PHYSLAYER_SRCS
    physfsrwops.c
    physfslualoader.c
    hwpacksmounter.c
)

set(build_type STATIC)
set(lib_prefix ${CMAKE_STATIC_LIBRARY_PREFIX})
set(lib_suffix ${CMAKE_STATIC_LIBRARY_SUFFIX})

if(WIN32)
    set(build_type SHARED)
    set(lib_prefix ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(lib_suffix ${CMAKE_SHARED_LIBRARY_SUFFIX})
endif(WIN32)

#compiles and links actual library
add_library (physlayer ${build_type} ${PHYSLAYER_SRCS})

if(WIN32)
    target_link_libraries(physlayer ${SDL_LIBRARY} ${LUA_LIBRARY} ${PHYSFS_LIBRARY})
    install(TARGETS physlayer RUNTIME DESTINATION ${target_library_install_dir})
endif()

## added standard variables (FORCE or cmake won't pick 'em)
set(PHYSLAYER_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/misc/libphyslayer/ CACHE STRING "" FORCE)
set(PHYSLAYER_LIBRARY ${LIBRARY_OUTPUT_PATH}/${lib_prefix}physlayer${lib_suffix} CACHE STRING "" FORCE)

