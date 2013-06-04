if(APPLE)
    #let's look for the installed sdlmain file; if it is not found, let's build our own
    find_package(SDL REQUIRED)

    include_directories(${SDL_INCLUDE_DIR})
    add_library (SDLmain STATIC ${CMAKE_CURRENT_SOURCE_DIR}/SDLMain.m)
endif(APPLE)

