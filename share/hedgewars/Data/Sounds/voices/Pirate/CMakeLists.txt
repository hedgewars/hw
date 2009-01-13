file(GLOB PirateSounds *.ogg)

install(FILES
	${PirateSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Pirate)
