file(GLOB Trainings t*.txt t*.lua)
file(GLOB Singleplayer s*.txt s*.lua)
file(GLOB Cooperative c*.txt c*.lua)

install(FILES
	${Trainings}
	${Singleplayer}
	${Cooperative}
	DESTINATION ${SHAREPATH}Data/Trainings)
