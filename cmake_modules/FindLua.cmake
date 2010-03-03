# Find the Lua library
#

IF(UNIX)
  FIND_LIBRARY(LUA_LIBRARY NAMES lua5.1 lua)
ELSE(UNIX)
  IF(WIN32)
    SET(LUA_LIBRARY lua.dll CACHE FILEPATH "Path to the lua library to be used. This should be set to 'lua.dll' or 'lua' under Win32/Apple to use the bundled copy.")
  else(WIN32)
  ENDIF(WIN32)
ENDIF(UNIX)