file(GLOB BaseMusic *.ogg)

install(FILES
    ${BaseMusic}
    ${MusicCredits}
    credits.txt
    DESTINATION ${SHAREPATH}Data/Music)
