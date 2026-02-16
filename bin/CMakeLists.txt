if(WIN32 AND NOT UNIX)
    install(DIRECTORY .
        DESTINATION ${target_library_install_dir}
		FILES_MATCHING PATTERN "*.dll" PATTERN "*.ico" 
		)
endif(WIN32 AND NOT UNIX)

set(EXTERNAL_BIN_DIR "" CACHE PATH "Directory with additional libraries to put into target directory")

if(EXTERNAL_BIN_DIR)
    if(IS_DIRECTORY "${EXTERNAL_BIN_DIR}")
        install(DIRECTORY "${EXTERNAL_BIN_DIR}/"
                DESTINATION ${target_library_install_dir}
                COMPONENT Runtime
        )
    else()
        message(WARNING "EXTERNAL_BIN_DIR is set to '${EXTERNAL_BIN_DIR}', but it is not a valid directory.")
    endif()
endif()

