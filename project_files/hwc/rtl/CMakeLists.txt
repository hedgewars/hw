
include_directories(${GLEW_INCLUDE_DIR})

file(GLOB fpcrtl_src *.c)

add_library(fpcrtl STATIC ${fpcrtl_src})

