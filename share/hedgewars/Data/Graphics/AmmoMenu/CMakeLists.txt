file(GLOB AmmoMenuSprites *.png)

install(FILES
	${AmmoMenuSprites}
	DESTINATION ${SHAREPATH}Data/Graphics/AmmoMenu)
