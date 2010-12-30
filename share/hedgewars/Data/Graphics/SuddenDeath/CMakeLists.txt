file(GLOB Sprites *.png)

install(FILES
	${Sprites}
	DESTINATION ${SHAREPATH}Data/Graphics/SuddenDeath)
