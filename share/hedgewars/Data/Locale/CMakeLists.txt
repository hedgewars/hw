file(GLOB txttrans ??.txt)
file(GLOB qmtrans hedgewars_*.qm)

install(FILES
	${txttrans}
	${qmtrans}
	DESTINATION ${SHAREPATH}Data/Locale)
