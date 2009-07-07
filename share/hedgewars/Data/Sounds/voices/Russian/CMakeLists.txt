file(GLOB RussianSounds *.ogg)

install(FILES
	${RussianSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Russian)
