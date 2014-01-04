find_package(SDL QUIET)

if(NOT SDL_FOUND)
    find_package(SDL2 REQUIRED)
    set(SDL_INCLUDE_DIR ${SDL2_INCLUDE_DIR})
    set(SDL_LIBRARY ${SDL2_LIBRARY})
endif()

if(NOT SDL_VERSION)
    #find which version of SDL we have
    find_file(sdlversion_h SDL_version.h ${SDL_INCLUDE_DIR})
    if(sdlversion_h)
        file(STRINGS ${sdlversion_h} sdl_majorversion_tmp REGEX "SDL_MAJOR_VERSION[\t' ']+[0-9]+")
        file(STRINGS ${sdlversion_h} sdl_minorversion_tmp REGEX "SDL_MINOR_VERSION[\t' ']+[0-9]+")
        file(STRINGS ${sdlversion_h} sdl_patchversion_tmp REGEX "SDL_PATCHLEVEL[\t' ']+[0-9]+")
        string(REGEX MATCH "([0-9]+)" sdl_majorversion "${sdl_majorversion_tmp}")
        string(REGEX MATCH "([0-9]+)" sdl_minorversion "${sdl_minorversion_tmp}")
        string(REGEX MATCH "([0-9]+)" sdl_patchversion "${sdl_patchversion_tmp}")
        set(SDL_VERSION "${sdl_majorversion}.${sdl_minorversion}.${sdl_patchversion}")
    endif()
endif()

mark_as_advanced(sdlversion_h sdl_majorversion sdl_minorversion sdl_patchversion)

