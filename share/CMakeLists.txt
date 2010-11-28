add_subdirectory(hedgewars)

IF(APPLE)
	#needed for CFBundleVersion and CFBundleShortVersionString
	FIND_PROGRAM(HGCOMMAND hg)
	IF (HGCOMMAND AND (EXISTS ${hedgewars_SOURCE_DIR}/.hg))
		exec_program(${HGCOMMAND}
			     ARGS identify -n ${hedgewars_SOURCE_DIR}
			     OUTPUT_VARIABLE version_suffix
			     )
		STRING(REGEX REPLACE "([0-9]+)(.*)" "\\1" version_suffix ${version_suffix})
		set (HEDGEWARS_REVISION ${version_suffix})
	ELSE ()
		set (HEDGEWARS_REVISION ${HEDGEWARS_VERSION})
	ENDIF ()

	configure_file(${hedgewars_SOURCE_DIR}/share/Info.plist.in 
		${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
	install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
		DESTINATION ../)
	install(PROGRAMS "${hedgewars_SOURCE_DIR}/misc/Icon.icns"
		DESTINATION ../Resources/)
	install(PROGRAMS "${hedgewars_SOURCE_DIR}/misc/dsa_pub.pem"
		DESTINATION ../Resources/)
ENDIF(APPLE)
