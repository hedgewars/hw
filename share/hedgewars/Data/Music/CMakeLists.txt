file(GLOB BaseMusic *.ogg)

install(FILES
    ${BaseMusic}
    DESTINATION ${SHAREPATH}Data/Music)
