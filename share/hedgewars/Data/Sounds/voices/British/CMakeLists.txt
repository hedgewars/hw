file(GLOB BritishSounds *.ogg)

install(FILES
	${BritishSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/British)

