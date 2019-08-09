file(GLOB BaseMusic *.ogg *.opus)

install(FILES
    ${BaseMusic}
    ${MusicCredits}
    credits.txt
    DESTINATION ${SHAREPATH}Data/Music)
