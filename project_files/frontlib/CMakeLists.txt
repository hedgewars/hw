find_package(SDL_net REQUIRED)

set(CMAKE_C_FLAGS "-std=c99")

file(GLOB frontlib_src
        *.c *.h
        base64/*.c base64/*.h
        ipc/*.c ipc/*.h
        md5/*.c md5/*.h
        model/*.c model/*.h
        net/*.c net/*.h
        util/*.c util/*.h
    )

include_directories(${SDLNET_INCLUDE_DIR})

add_library(frontlib STATIC ${frontlib_src})
