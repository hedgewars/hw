# Find the Lua library
#

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
				#UNSET(LUA_DEFAULT)
				MESSAGE(FATAL_ERROR "Couldn't find Lua 5.1 library!")
			ENDIF()
			#remove the path (fpc doesn't like it - why?)
			GET_FILENAME_COMPONENT(LUA_DEFAULT ${LUA_DEFAULT} NAME)
                ENDIF(APPLE
	ENDIF(WIN32)
ENDIF(ANDROID)
SET(LUA_LIBRARY ${LUA_DEFAULT} CACHE STRING "Lua library to link to; file name without path only!")
#UNSET(LUA_DEFAULT)
