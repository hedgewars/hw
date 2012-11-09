
set(fpcrtl_src  fileio.c
                misc.c
                pmath.c
                system.c
                sysutils.c
)

include_directories(${GLEW_INCLUDE_PATH})

add_library(fpcrtl ${fpcrtl_src})

if(WEBGL)
    set_target_properties(fpcrtl PROPERTIES PREFIX "em")
    set_target_properties(fpcrtl PROPERTIES SUFFIX ".bc")
endif(WEBGL)





