file(GLOB tiles *.png)

install(FILES
    ${tiles}
    DESTINATION ${SHAREPATH}Data/Tiles)
