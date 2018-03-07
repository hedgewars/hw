file(GLOB Scripts *.lua)

install(FILES
    ${Scripts}
    order.cfg
    DESTINATION ${SHAREPATH}Data/Missions/Challenge)
