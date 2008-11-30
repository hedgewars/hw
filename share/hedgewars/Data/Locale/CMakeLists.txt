file(GLOB txttrans ??.txt)
file(GLOB qmtrans hedgewars_*.qm)

install(FILES
	pt-br.txt	
	${txttrans}
	${qmtrans}
	DESTINATION ${SHAREPATH}Data/Locale)
