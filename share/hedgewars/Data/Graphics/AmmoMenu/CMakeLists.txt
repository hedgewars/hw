file(GLOB AmmoMenuSprites *.png)
list(REMOVE_ITEM AmmoMenuSprites *_iPhone.png)

install(FILES
	${AmmoMenuSprites}
	DESTINATION ${SHAREPATH}Data/Graphics/AmmoMenu)
