file(GLOB MissionPics *@2x.png)

install(FILES
    ${MissionPics}
    DESTINATION ${SHAREPATH}Data/Graphics/Missions/Campaign/A_Classic_Fairytale)
