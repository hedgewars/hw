if(DEFINED DATA_INSTALL_DIR)
    set(HEDGEWARS_DATADIR ${DATA_INSTALL_DIR}
)
else()
    set(HEDGEWARS_DATADIR ${CMAKE_INSTALL_PREFIX}/share/)
endif()  

if(UNIX AND NOT APPLE)
configure_file(hwengine.desktop.in hwengine.desktop)
endif()

file(GLOB miscfiles *.xml *.desktop)

install(FILES ${miscfiles} DESTINATION ${SHAREPATH}Data/misc)
