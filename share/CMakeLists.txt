add_subdirectory(hedgewars)
IF(APPLE)
	configure_file(${hedgewars_SOURCE_DIR}/share/Info.plist.in 
		${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
ENDIF(APPLE)
