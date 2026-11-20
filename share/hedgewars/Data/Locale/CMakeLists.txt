file(GLOB txttrans2       CONFIGURE_DEPENDS ??.txt)
file(GLOB txttrans5       CONFIGURE_DEPENDS ?????.txt)
file(GLOB luafiles        CONFIGURE_DEPENDS *.lua)
file(GLOB missionfiles    CONFIGURE_DEPENDS missions_*.txt)
file(GLOB campaignfiles   CONFIGURE_DEPENDS campaigns_*.txt)
file(GLOB tipfiles        CONFIGURE_DEPENDS tips_*.xml)

install(FILES
    ${txttrans2}
    ${txttrans5}
    ${luafiles}
    ${missionfiles}
    ${campaignfiles}
    ${tipfiles}
    DESTINATION ${SHAREPATH}Data/Locale
)
