add_subdirectory(AmmoMenu)
add_subdirectory(Flags)
add_subdirectory(Graves)
add_subdirectory(Hats)
add_subdirectory(Hedgehog)
add_subdirectory(SuddenDeath)

file(GLOB BaseSprites *.png) 

install(FILES
	${BaseSprites}
	DESTINATION ${SHAREPATH}Data/Graphics)
