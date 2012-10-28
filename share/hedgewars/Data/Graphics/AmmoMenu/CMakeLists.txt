file(GLOB AmmoMenuSprites *.png)
list(REMOVE_ITEM AmmoMenuSprites *@2x.png Border*.png)

install(FILES
	${AmmoMenuSprites}
	DESTINATION ${SHAREPATH}Data/Graphics/AmmoMenu)
