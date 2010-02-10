file(GLOB Trainings *.hwt)
file(GLOB Singleplayer *.hwm)
file(GLOB Cooperative *.hwc)

install(FILES
	${Trainings}
	${Singleplayer}
	${Cooperative}
	DESTINATION ${SHAREPATH}Data/Missions)
