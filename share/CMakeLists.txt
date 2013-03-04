
set(SHAREPATH ${HEDGEWARS_DATADIR})

add_subdirectory(hedgewars/Data)

if(APPLE)
    #CFBundleVersion is HEDGEWARS_REVISION
    #CFBundleShortVersionString is HEDGEWARS_VERSION

    #silly libav that always brings in VideoDecoderAcceleration, avaible only from 10.6.3
    if(NOT NOVIDEOREC)
        set(FFMPEG_FIND_QUIETLY true)
        find_package(FFMPEG)
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
endif(APPLE)
