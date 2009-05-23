file(GLOB MobsterSounds *.ogg *.wav)

install(FILES
	${MobsterSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Mobster)
