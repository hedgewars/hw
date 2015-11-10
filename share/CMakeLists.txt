
set(SHAREPATH ${HEDGEWARS_DATADIR})

add_subdirectory(hedgewars/Data)

if(APPLE)
    #CFBundleVersion is HEDGEWARS_REVISION
    #CFBundleShortVersionString is HEDGEWARS_VERSION

    #libav/ffmpeg always brings in VideoDecoderAcceleration, avaible only from 10.6.3
    if(LIBAV_FOUND AND ${minimum_macosx_version} VERSION_EQUAL "10.6")
        set(minimum_macosx_version "10.6.3")
    endif()

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
