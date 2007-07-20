add_subdirectory(Graves)
add_subdirectory(AmmoMenu)

file(GLOB BaseSprites *.png) 

install(FILES
	${BaseSprites}
	DESTINATION ${SHAREPATH}Data/Graphics)
