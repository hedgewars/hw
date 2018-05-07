if(WIN32 AND NOT UNIX)
    install(DIRECTORY .
        DESTINATION ${target_library_install_dir}
		FILES_MATCHING PATTERN "*.dll" PATTERN "*.ico" 
		)
endif(WIN32 AND NOT UNIX)
