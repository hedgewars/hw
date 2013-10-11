file(GLOB txttrans2 ??.txt)
file(GLOB txttrans5 ?????.txt)
file(GLOB tsfiles *.ts)
file(GLOB luafiles *.lua)
file(GLOB missionfiles missions_*.txt)
file(GLOB campaignfiles campaigns_*.txt)

QT4_ADD_TRANSLATION(QM ${tsfiles})

add_custom_target (release-translation ALL
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
    DESTINATION ${SHAREPATH}Data/Locale
)

