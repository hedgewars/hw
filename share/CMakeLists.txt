add_subdirectory(hedgewars)

IF(APPLE OR CROSSAPPLE)
	#needed for CFBundleVersion and CFBundleShortVersionString
	FIND_PROGRAM(HGCOMMAND hg)
	IF (HGCOMMAND AND (EXISTS ${hedgewars_SOURCE_DIR}/.hg))
            execute_process(COMMAND ${HGCOMMAND} identify -in
                            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                            OUTPUT_VARIABLE internal_version
                            ERROR_QUIET
                        )
		STRING(REGEX REPLACE "([0-9]+)(.*)" "\\1" revision_number ${internal_version})
		set (HEDGEWARS_REVISION ${revision_number})
	ELSE ()
		set (HEDGEWARS_REVISION ${HEDGEWARS_VERSION})
	ENDIF ()

	configure_file(${hedgewars_SOURCE_DIR}/share/Info.plist.in 
		${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
	install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/Info.plist"
		DESTINATION ../)
	install(PROGRAMS "${hedgewars_SOURCE_DIR}/share/Icon.icns"
		DESTINATION ../Resources/)
	install(PROGRAMS "${hedgewars_SOURCE_DIR}/share/hwico.icns"
		DESTINATION ../Resources/)
	install(PROGRAMS "${hedgewars_SOURCE_DIR}/share/dsa_pub.pem"
		DESTINATION ../Resources/)
ENDIF(APPLE OR CROSSAPPLE)
