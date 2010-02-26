add_subdirectory(Reserved)

file(GLOB HatSprites *.png)

install(FILES
	${HatSprites}
	DESTINATION ${SHAREPATH}Data/Graphics/Hats)
