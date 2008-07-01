if(WIN32 AND NOT UNIX)
	file(GLOB DLLs *.dll)
	
	install(FILES
		${DLLs}
		DESTINATION bin)
endif(WIN32 AND NOT UNIX)
