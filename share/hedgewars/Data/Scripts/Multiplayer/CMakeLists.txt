file(GLOB luafiles *.lua)
file(GLOB cfgfiles *.cfg)

install(FILES
	${luafiles}
	${cfgfiles}
	DESTINATION ${SHAREPATH}Data/Scripts/Multiplayer)
