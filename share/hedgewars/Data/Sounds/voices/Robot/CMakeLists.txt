file(GLOB RobotSounds *.ogg)

install(FILES
	${RobotSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Robot)
