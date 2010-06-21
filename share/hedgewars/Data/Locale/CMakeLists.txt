file(GLOB txttrans2 ??.txt)
file(GLOB txttrans5 ?????.txt)

set(ts_files *.ts)
QT4_CREATE_TRANSLATION(qm_files ts_files)
#file(GLOB qmtrans hedgewars_*.qm)

install(FILES
	${txttrans2}
	${txttrans5}
	${qm_files}
	DESTINATION ${SHAREPATH}Data/Locale)
