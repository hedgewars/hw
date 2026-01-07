if(WIN32 AND NOT UNIX)
    install(DIRECTORY .
        DESTINATION ${target_library_install_dir}
		FILES_MATCHING PATTERN "*.dll" PATTERN "*.ico" 
		)
endif(WIN32 AND NOT UNIX)

option(EXTERNAL_BIN_DIR "Directory with additional libraries to put into target directory" "")

install(DIRECTORY "${EXTERNAL_BIN_DIR}/"
        DESTINATION ${target_library_install_dir}
        COMPONENT Runtime
)

