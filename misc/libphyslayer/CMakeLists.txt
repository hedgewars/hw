find_package(SDL2 REQUIRED)

include_directories(${SDL2_INCLUDE_DIR})
include_directories(${PHYSFS_INCLUDE_DIR})
include_directories(${LUA_INCLUDE_DIR})


set(PHYSLAYER_SRCS
    physfscompat.c
    physfsrwops.c
    physfslualoader.c
    hwpacksmounter.c
)

#compiles and links actual library
add_library (physlayer ${PHYSLAYER_SRCS})
#TODO: find good VERSION and SOVERSION values
target_link_libraries(physlayer ${SDL2_LIBRARY} lua physfs)
install(TARGETS physlayer RUNTIME DESTINATION ${target_binary_install_dir}
                          LIBRARY DESTINATION ${target_library_install_dir}
                          ARCHIVE DESTINATION ${target_library_install_dir})
get_target_property(physlayer_fullpath physlayer LOCATION)


## added standard variables (FORCE or cmake won't pick 'em)
set(PHYSLAYER_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "Physlayer include dir" FORCE)
set(PHYSLAYER_LIBRARY ${physlayer_fullpath} CACHE STRING "Physlayer library" FORCE)

if(BUILD_ENGINE_JS)
    set_target_properties(physlayer PROPERTIES SUFFIX ".bc")
endif()

