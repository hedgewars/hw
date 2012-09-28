#this file is included only when system Lua library is not found

file(GLOB lua_src *.c *.h)

if(WIN32)
    add_definitions(-DLUA_BUILD_AS_DLL)
    add_library(lua SHARED ${lua_src})

    set(LUA_LIBRARY lua.dll)

    set_target_properties(lua PROPERTIES PREFIX "")
    install(TARGETS lua RUNTIME DESTINATION ${target_dir})
else(WIN32)
    add_definitions(-DLUA_USE_LINUX)
    add_library(lua STATIC ${lua_src})
    set(LUA_LIBRARY lua)
endif(WIN32)



