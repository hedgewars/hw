
if(UNIX AND NOT APPLE)
    configure_file(hwengine.desktop.in hwengine.desktop)

    file(GLOB miscfiles *.xml *.desktop)

    install(FILES ${miscfiles} DESTINATION ${SHAREPATH}/Data/misc)
    install(FILES hedgewars.xpm DESTINATION ${CMAKE_INSTALL_PREFIX}/share/pixmaps)
endif()

