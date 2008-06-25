file(GLOB FortSprites *.png) 

install(FILES
	${FortSprites}
	DESTINATION ${SHAREPATH}Data/Forts)
