file(GLOB luafiles *.lua)
file(GLOB cfgfiles *.cfg)
file(GLOB hwpfiles *.hwp)

install(FILES
    ${luafiles}
    ${cfgfiles}
    ${hwpfiles}
    DESTINATION ${SHAREPATH}Data/Scripts/Multiplayer)
