add_subdirectory("A_Classic_Fairytale")

file(GLOB Scripts *.lua)

install(FILES
    ${Scripts}
    DESTINATION ${SHAREPATH}Data/Missions/Campaign)
