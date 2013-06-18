
include_directories(${GLEW_INCLUDE_DIR})

file(GLOB fpcrtl_src *.c)

add_library(fpcrtl STATIC ${fpcrtl_src})

#if(WEBGL)
#    set_target_properties(fpcrtl PROPERTIES PREFIX "em")
#    set_target_properties(fpcrtl PROPERTIES SUFFIX ".bc")
#endif(WEBGL)





