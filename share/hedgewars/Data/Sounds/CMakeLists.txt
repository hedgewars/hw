add_subdirectory(voices)

file(GLOB BaseSounds *.ogg) 

install(FILES
	${BaseSounds}
	DESTINATION ${SHAREPATH}Data/Sounds)
