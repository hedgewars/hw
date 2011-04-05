file(GLOB BaseSounds *.ogg)

install(FILES
	${BaseSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Default_uk)
