# Find the Lua library
# --------------------
# On Android/Windows/OSX this just defines the name of the library that
#  will be compiled from our bundled sources
# On Linux it will try to load the system library and fallback to compiling
#  the bundled one when nothing is found

set(LUA_FOUND false)
set(LUA_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/misc/liblua)

if (ANDROID)
    SET(LUA_DEFAULT "liblua5.1.so")
else (ANDROID)
    IF(WIN32)
        SET(LUA_DEFAULT lua.dll)
    ELSE(WIN32)
        IF(APPLE)
            SET(LUA_DEFAULT lua)
        ELSE(APPLE)
            #locate the system's lua library
            FIND_LIBRARY(LUA_DEFAULT NAMES lua51 lua5.1 lua-5.1 lua PATHS /lib /usr/lib /usr/local/lib /usr/pkg/lib)
            IF(${LUA_DEFAULT} MATCHES "LUA_DEFAULT-NOTFOUND")
                set(LUA_DEFAULT lua)
            ELSE()
                set(LUA_FOUND true)
                message(STATUS "LibLua 5.1 found at ${LUA_DEFAULT}")
                find_path(LUA_INCLUDE_DIR lua.h)
                #remove the path (fpc doesn't like it - why?)
                GET_FILENAME_COMPONENT(LUA_DEFAULT ${LUA_DEFAULT} NAME)
            ENDIF()
        ENDIF(APPLE)
    ENDIF(WIN32)
ENDIF(ANDROID)

SET(LUA_LIBRARY ${LUA_DEFAULT} CACHE STRING "Lua library to link to; file name without path only!")


