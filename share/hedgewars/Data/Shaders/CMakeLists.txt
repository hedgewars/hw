file(GLOB vertshaders *.vs)
file(GLOB fragshaders *.fs)

install(FILES
    ${vertshaders}
    ${fragshaders}
    DESTINATION ${SHAREPATH}Data/Shaders)
