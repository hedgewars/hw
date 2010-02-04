file(GLOB FlagTemplates *.png) 

install(FILES
	${FlagTemplates}
	DESTINATION ${SHAREPATH}Data/Graphics/Flags)
