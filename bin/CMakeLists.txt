if(WIN32 AND NOT UNIX)
	file(GLOB DLLs *.dll)
	file(GLOB ICOs *.ico)
	file(GLOB TXTs *.txt)
	
	install(FILES
		${DLLs}
		${ICOs}
		${TXTs}
		DESTINATION bin)
endif(WIN32 AND NOT UNIX)
