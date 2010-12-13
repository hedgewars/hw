file(GLOB luafiles *.lua)

install(FILES
	${luafiles}
	DESTINATION ${SHAREPATH}Data/Scripts)

add_subdirectory(Multiplayer)
