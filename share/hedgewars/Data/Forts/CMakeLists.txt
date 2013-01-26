file(GLOB FortSprites *L.png *R.png)
list(REMOVE_ITEM FortSprites *@2x.png)
list(REMOVE_ITEM FortSprites *-icon.png)

install(FILES
    ${FortSprites}
    DESTINATION ${SHAREPATH}Data/Forts)
