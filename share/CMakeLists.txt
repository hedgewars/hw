add_subdirectory(hedgewars)

IF(APPLE OR CROSSAPPLE)
	#needed for CFBundleVersion and CFBundleShortVersionString
	FIND_PROGRAM(HGCOMMAND hg)
	IF (HGCOMMAND AND (EXISTS ${CMAKE_SOURCE_DIR}/.hg))
		exec_program(${HGCOMMAND}
			     ARGS identify -n ${CMAKE_SOURCE_DIR}
			     OUTPUT_VARIABLE version_suffix
			     )
		STRING(REGEX REPLACE "([0-9]+)(.*)" "\\1" version_suffix ${version_suffix})
		set (HEDGEWARS_REVISION ${version_suffix})
	ELSE ()
		set (HEDGEWARS_REVISION ${HEDGEWARS_VERSION})
	ENDIF ()

	configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in
		${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
	install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
		DESTINATION ../)
	install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/Icon.icns"
		DESTINATION ../Resources/)
	install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/share/hwico.icns"
		DESTINATION ../Resources/)
	install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/share/dsa_pub.pem"
		DESTINATION ../Resources/)
ENDIF(APPLE OR CROSSAPPLE)
