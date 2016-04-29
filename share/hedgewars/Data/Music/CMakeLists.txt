file(GLOB BaseMusic *.ogg)
file(GLOB MusicCredits *_credits.txt)

install(FILES
    ${BaseMusic}
    ${MusicCredits}
    DESTINATION ${SHAREPATH}Data/Music)
