file(GLOB SurferSounds *.ogg *.wav)

install(FILES
	${SurferSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Surfer)
