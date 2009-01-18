file(GLOB SingerSounds *.ogg *.wav)

install(FILES
	${SingerSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Singer)
