find_package(SDL REQUIRED)

include_directories(${SDL_INCLUDE_DIR})

add_library (SDLmain STATIC SDLMain.m)


