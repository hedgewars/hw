file(GLOB SurferSounds *.ogg)

install(FILES
	${SurferSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Surfer)
