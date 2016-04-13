file(GLOB MissionPics *@2x.png)

install(FILES
    ${MissionPics}
    DESTINATION ${SHAREPATH}Data/Graphics/Missions/Scenario)
