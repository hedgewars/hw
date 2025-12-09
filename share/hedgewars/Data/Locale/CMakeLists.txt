find_package(Qt6 REQUIRED COMPONENTS LinguistTools)

file(GLOB txttrans2       CONFIGURE_DEPENDS ??.txt)
file(GLOB txttrans5       CONFIGURE_DEPENDS ?????.txt)
file(GLOB tsfiles         CONFIGURE_DEPENDS hedgewars_*.ts)
file(GLOB luafiles        CONFIGURE_DEPENDS *.lua)
file(GLOB missionfiles    CONFIGURE_DEPENDS missions_*.txt)
file(GLOB campaignfiles   CONFIGURE_DEPENDS campaigns_*.txt)
file(GLOB tipfiles        CONFIGURE_DEPENDS tips_*.xml)

qt_add_translation(QM ${tsfiles})

add_custom_target(release-translation ALL
    DEPENDS ${QM}
    COMMENT "Compiling ts files"
)

install(FILES
    ${txttrans2}
    ${txttrans5}
    ${QM}
    ${luafiles}
    ${missionfiles}
    ${campaignfiles}
    ${tipfiles}
    DESTINATION ${SHAREPATH}Data/Locale
)

