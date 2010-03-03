# Find the Lua library
#

IF(NOT LUA_LIBRARY)
	IF(WIN32)
		set(LUA_DEFAULT lua.dll)
	ELSE(WIN32)
		IF(APPLE)
			set(LUA_DEFAULT lua)
		ELSE(APPLE)
			set(LUA_DEFAULT lua5.1.so)
		ENDIF(APPLE)
	ENDIF(WIN32)
	SET(LUA_LIBRARY ${LUA_DEFAULT} CACHE STRING "Lua library to link to; file name without path only!")
ENDIF(NOT LUA_LIBRARY)