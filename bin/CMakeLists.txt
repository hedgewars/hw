if(WIN32 AND NOT UNIX)
	file(GLOB DLLs *.dll)
	file(GLOB ICOs *.ico)
	
	install(FILES
		${DLLs}
		${ICOs}
		DESTINATION bin)
endif(WIN32 AND NOT UNIX)
