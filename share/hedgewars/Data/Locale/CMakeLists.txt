file(GLOB txttrans2 ??.txt)
file(GLOB txttrans5 ?????.txt)
file(GLOB qmtrans hedgewars_*.qm)

install(FILES
	${txttrans2}
	${txttrans5}
	${qmtrans}
	DESTINATION ${SHAREPATH}Data/Locale)
