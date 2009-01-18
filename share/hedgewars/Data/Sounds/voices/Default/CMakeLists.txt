file(GLOB BaseSounds *.ogg *.wav)

install(FILES
	${BaseSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Default)
