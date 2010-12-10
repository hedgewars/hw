file(GLOB luafiles *.lua)

install(FILES
	${luafiles}
	DESTINATION ${SHAREPATH}Data/Scripts)

