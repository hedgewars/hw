file(GLOB MobsterSounds *.ogg)

install(FILES
	${MobsterSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Mobster)
