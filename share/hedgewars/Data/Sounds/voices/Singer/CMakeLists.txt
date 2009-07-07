file(GLOB SingerSounds *.ogg)

install(FILES
	${SingerSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Singer)
