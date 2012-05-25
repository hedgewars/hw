file(GLOB BaseShaders *.vs *.fs)

install(FILES
	${BaseShaders}
	DESTINATION ${SHAREPATH}Data/Shaders)
