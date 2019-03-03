file(GLOB images *.png)
file(GLOB credits.txt credits)

install(FILES
    theme.cfg
    ${images}
    credits.txt
    DESTINATION ${SHAREPATH}Data/Themes/Cave)
