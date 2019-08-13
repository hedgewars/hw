
set(SHAREPATH ${HEDGEWARS_DATADIR})

add_subdirectory(hedgewars/Data)

if(APPLE)
    #CFBundleVersion is HEDGEWARS_REVISION
    #CFBundleShortVersionString is HEDGEWARS_VERSION

    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in
                   ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
    #path here should be Hedgewars.app/Contents/MacOS
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
            DESTINATION ../)
    install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/Icon.icns"
            DESTINATION ../Resources/)
    install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/hwico.icns"
            DESTINATION ../Resources/)
    install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/dsa_pub.pem"
            DESTINATION ../Resources/)
elseif(UNIX)
    install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/hedgewars.appdata.xml"
            DESTINATION ${CMAKE_INSTALL_PREFIX}/share/appdata/)
endif()
