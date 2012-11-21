add_subdirectory(hedgewars)

IF(APPLE OR CROSSAPPLE)
    #needed for CFBundleVersion and CFBundleShortVersionString
        #should reuse the variables set in main CMakeLists.txt
    IF(HGCOMMAND AND (EXISTS ${CMAKE_SOURCE_DIR}/.hg))
        set(HEDGEWARS_REVISION ${revision_number})
    ELSE()
        set(HEDGEWARS_REVISION ${HEDGEWARS_VERSION})
    ENDIF()

    configure_file(${hedgewars_SOURCE_DIR}/share/Info.plist.in
                   ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
    #path here should be Hedgewars.app/Contents/MacOS
    install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
            DESTINATION ../)
    install(PROGRAMS "${hedgewars_SOURCE_DIR}/share/Icon.icns"
            DESTINATION ../Resources/)
    install(PROGRAMS "${hedgewars_SOURCE_DIR}/share/hwico.icns"
            DESTINATION ../Resources/)
    install(PROGRAMS "${hedgewars_SOURCE_DIR}/share/dsa_pub.pem"
            DESTINATION ../Resources/)
ENDIF(APPLE OR CROSSAPPLE)
