add_subdirectory("A Classic Fairytale")

file(GLOB Scripts *.lua)

install(FILES
	${Scripts}
	DESTINATION ${SHAREPATH}Data/Missions/Campaign)
