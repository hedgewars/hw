file(GLOB Scripts *.lua)

install(FILES
    order.cfg
    ${Scripts}
    DESTINATION ${SHAREPATH}Data/Missions/Training)
