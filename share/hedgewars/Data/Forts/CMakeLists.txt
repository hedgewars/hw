file(GLOB FortSprites *{L,R}.png) 

install(FILES
	${FortSprites}
	DESTINATION ${SHAREPATH}Data/Forts)
