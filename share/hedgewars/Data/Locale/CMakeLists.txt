find_package(Qt6 REQUIRED COMPONENTS LinguistTools)

file(GLOB txttrans2       CONFIGURE_DEPENDS ??.txt)
file(GLOB txttrans5       CONFIGURE_DEPENDS ?????.txt)
file(GLOB tsfiles         CONFIGURE_DEPENDS hedgewars_*.ts)
file(GLOB luafiles        CONFIGURE_DEPENDS *.lua)
file(GLOB missionfiles    CONFIGURE_DEPENDS missions_*.txt)
file(GLOB campaignfiles   CONFIGURE_DEPENDS campaigns_*.txt)
file(GLOB tipfiles        CONFIGURE_DEPENDS tips_*.xml)

if(TARGET Qt6::lrelease)
    foreach(ts_file ${tsfiles})
        get_filename_component(ts_name ${ts_file} NAME_WE)
        set(qm_file "${CMAKE_CURRENT_BINARY_DIR}/${ts_name}.qm")
        add_custom_command(
            OUTPUT ${qm_file}
            COMMAND Qt6::lrelease ${ts_file} -qm ${qm_file}
            DEPENDS ${ts_file}
            VERBATIM
        )
        list(APPEND QM ${qm_file})
    endforeach()
endif()

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
