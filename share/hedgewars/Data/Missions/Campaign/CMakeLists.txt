add_subdirectory("A_Classic_Fairytale")
add_subdirectory("A_Space_Adventure")

file(GLOB Scripts *.lua)

install(FILES
    ${Scripts}
    DESTINATION ${SHAREPATH}Data/Missions/Campaign)
