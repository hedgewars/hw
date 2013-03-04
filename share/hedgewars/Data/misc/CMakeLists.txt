
if(UNIX AND NOT APPLE)
    configure_file(hwengine.desktop.in hwengine.desktop)

    file(GLOB miscfiles *.xml *.desktop)

    install(FILES ${miscfiles} DESTINATION ${HEDGEWARS_FULL_DATADIR}/Data/misc)
endif()

