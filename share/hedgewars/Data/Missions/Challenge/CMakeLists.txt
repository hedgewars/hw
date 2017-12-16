file(GLOB Scripts *.lua)

install(FILES
    ${Scripts}
    DESTINATION ${SHAREPATH}Data/Missions/Challenge)
