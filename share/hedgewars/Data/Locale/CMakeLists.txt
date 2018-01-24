find_package(Qt5 COMPONENTS LinguistTools)

file(GLOB txttrans2 ??.txt)
file(GLOB txttrans5 ?????.txt)
file(GLOB tsfiles *.ts)
file(GLOB luafiles *.lua)
file(GLOB missionfiles missions_*.txt)
file(GLOB campaignfiles campaigns_*.txt)
file(GLOB tipfiles tips_*.xml)

QT5_ADD_TRANSLATION(QM ${tsfiles})

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
    ${tipfiles}
    DESTINATION ${SHAREPATH}Data/Locale
)

