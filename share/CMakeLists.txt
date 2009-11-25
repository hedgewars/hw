add_subdirectory(hedgewars)

IF(APPLE)
	configure_file(${hedgewars_SOURCE_DIR}/share/Info.plist.in 
		${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
	install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
		DESTINATION ../)
	install(PROGRAMS "${hedgewars_SOURCE_DIR}/misc/Icon.icns"
		DESTINATION ../Resources/)
	install(PROGRAMS "${hedgewars_SOURCE_DIR}/misc/dsa_pub.pem"
		DESTINATION ../Resources/)
ENDIF(APPLE)
