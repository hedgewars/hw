
if(UNIX AND NOT APPLE)
    configure_file(hwengine.desktop.in hwengine.desktop)

    file(GLOB miscfiles *.svg *.xml *.desktop)

    install(FILES ${miscfiles} DESTINATION ${SHAREPATH}/Data/misc)
    install(FILES hedgewars.xpm DESTINATION ${CMAKE_INSTALL_PREFIX}/share/pixmaps)
    install(FILES hedgewars.desktop DESTINATION ${CMAKE_INSTALL_PREFIX}/share/applications)
endif()

