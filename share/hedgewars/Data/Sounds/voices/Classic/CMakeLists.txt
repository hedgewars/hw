file(GLOB ClassicSounds *.ogg)

install(FILES
	${ClassicSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Classic)

