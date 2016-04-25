#this file is included only when system Lua library is not found

file(GLOB lua_src *.c *.h)

if(WIN32)
    add_definitions(-DLUA_BUILD_AS_DLL)
else(WIN32)
    add_definitions(-DLUA_USE_LINUX)
    add_definitions(-fvisibility=default) #TODO: fixme
endif(WIN32)

add_library(lua ${lua_src})

set_target_properties(lua PROPERTIES
                          VERSION "5.1.4"
                          SOVERSION 1
                          OUTPUT_NAME ${lua_output_name})
install(TARGETS lua RUNTIME DESTINATION ${target_binary_install_dir}
                    LIBRARY DESTINATION ${target_library_install_dir}
                    ARCHIVE DESTINATION ${target_library_install_dir})
get_target_property(lua_fullpath lua LOCATION)

set(LUA_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "Lua include dir" FORCE)
set(LUA_LIBRARY ${lua_fullpath} CACHE STRING "Lua library" FORCE)

#emscripten does not expose headers but has an internal binary copy
if(BUILD_ENGINE_JS)
    set(LUA_LIBRARY "lua_emscripten_internal" CACHE STRING "Lua library" FORCE)
endif()

