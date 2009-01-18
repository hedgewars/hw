file(GLOB PirateSounds *.ogg *.wav)

install(FILES
	${PirateSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Pirate)
