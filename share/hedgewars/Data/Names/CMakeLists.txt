file(GLOB txtnames *.txt)
file(GLOB cfgnames *.cfg)

install(FILES
    types.ini
    ${txtnames}
    ${cfgnames}
    DESTINATION ${SHAREPATH}Data/Names)
