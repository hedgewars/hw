file(GLOB HedgehogSprites *.png)

install(FILES
	${HedgehogSprites}
	DESTINATION ${SHAREPATH}Data/Graphics/Hedgehog)
