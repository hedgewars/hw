find_package(SDL REQUIRED)

include_directories(${SDL_INCLUDE_DIR})
include_directories(${LUA_INCLUDE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/misc/physfs/src)

add_library(physfsrwops STATIC physfsrwops.c physfslualoader.c hwpacksmounter.c)

