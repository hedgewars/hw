file(GLOB FortSprites *L.png *R.png) 

install(FILES
	${FortSprites}
	DESTINATION ${SHAREPATH}Data/Forts)
