file(GLOB Trainings 0*.txt)

install(FILES
	${Trainings}
	DESTINATION ${SHAREPATH}Data/Trainings)
