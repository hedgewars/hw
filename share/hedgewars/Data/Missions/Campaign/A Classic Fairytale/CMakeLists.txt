file(GLOB Config *.ini)
file(GLOB Missions *.lua)
file(GLOB Packs *.hwp)

install(FILES
    ${Config}
    ${Missions}
    ${Packs}
    DESTINATION "${SHAREPATH}Data/Missions/Campaign/A Classic Fairytale")
