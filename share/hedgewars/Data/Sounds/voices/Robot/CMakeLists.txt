file(GLOB RobotSounds *.ogg *.wav)

install(FILES
	${RobotSounds}
	DESTINATION ${SHAREPATH}Data/Sounds/voices/Robot)
