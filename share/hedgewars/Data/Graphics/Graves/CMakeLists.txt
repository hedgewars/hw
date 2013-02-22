file(GLOB GraveSprites *.png)

install(FILES
    ${GraveSprites}
    DESTINATION ${SHAREPATH}Data/Graphics/Graves)
