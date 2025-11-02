file(GLOB Scripts *.lua)
file(GLOB Packs *.hwp)

install(FILES
    ${Scripts}
    ${Packs}
    order.cfg
    DESTINATION ${SHAREPATH}Data/Missions/Scenario)
