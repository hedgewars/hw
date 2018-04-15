if(WIN32 AND NOT UNIX)
    file(GLOB_RECURSE DLLs *.dll)
    file(GLOB ICOs *.ico)

    install(FILES
        ${DLLs}
        ${ICOs}
        DESTINATION ${target_library_install_dir})
endif(WIN32 AND NOT UNIX)
