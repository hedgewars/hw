file(GLOB Config *.ini)
file(GLOB Missions *.lua)

install(FILES
    ${Config}
    ${Missions}
    DESTINATION "${SHAREPATH}Data/Missions/Campaign/A Classic Fairytale")
