find_package(SDL2 REQUIRED)

include_directories(${SDL2_INCLUDE_DIR})

add_library (SDLmain STATIC SDLMain.m)


