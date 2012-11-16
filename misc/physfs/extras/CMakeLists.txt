find_package(SDL REQUIRED)

include_directories(${SDL_INCLUDE_DIR})
include_directories(${CMAKE_SOURCE_DIR}/misc/liblua)
include_directories(${CMAKE_SOURCE_DIR}/misc/physfs/src)

add_library(physfsrwops STATIC physfsrwops.c physfslualoader.c)

add_dependencies(physfsrwops lua)
