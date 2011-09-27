file(GLOB MissionPics *.png)

install(FILES
	${MissionPics}
	DESTINATION ${SHAREPATH}Data/Graphics/Missions/Training)
