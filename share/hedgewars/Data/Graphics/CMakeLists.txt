add_subdirectory(AmmoMenu)
add_subdirectory(Flags)
add_subdirectory(Graves)
add_subdirectory(Hats)
add_subdirectory(Hedgehog)
add_subdirectory(SuddenDeath)
add_subdirectory(Missions)

file(GLOB BaseSprites *.png) 
list(REMOVE_ITEM BaseSprites *@2x.png)

install(FILES
	${BaseSprites}
	DESTINATION ${SHAREPATH}Data/Graphics)
