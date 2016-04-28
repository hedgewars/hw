file(GLOB images *.png)

install(FILES
    theme.cfg
    ${images}
    credits.txt
    DESTINATION ${SHAREPATH}Data/Themes/Jungle)
