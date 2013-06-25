add_subdirectory("A Classic Fairytale")
add_subdirectory("A Space Adventure")

file(GLOB Scripts *.lua)

install(FILES
    ${Scripts}
    DESTINATION ${SHAREPATH}Data/Missions/Campaign)
