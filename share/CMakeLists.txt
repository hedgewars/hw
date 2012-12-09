add_subdirectory(hedgewars)

if(APPLE OR CROSSAPPLE)
    #needed for CFBundleVersion and CFBundleShortVersionString
        #should reuse the variables set in main CMakeLists.txt
    if(HGCOMMAND AND (EXISTS ${CMAKE_SOURCE_DIR}/.hg))
        set(HEDGEWARS_REVISION ${revision_number})
    else()
        set(HEDGEWARS_REVISION ${HEDGEWARS_VERSION})
    endif()

    #silly libav that always brings in VideoDecoderAcceleration, avaible only from 10.6.3
    if(NOT NOVIDEOREC)
        find_package(FFMPEG QUIET)
        if(${FFMPEG_FOUND} AND ${minimum_macosx_version} VERSION_EQUAL "10.6")
            set(minimum_macosx_version "10.6.3")
        endif()
    endif()

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
endif(APPLE OR CROSSAPPLE)
