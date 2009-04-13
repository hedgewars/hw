file(GLOB RussianSounds *.ogg *.wav)

install(FILES
	${RussianSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Russian)
