file(GLOB txttrans2 ??.txt)
file(GLOB txttrans5 ?????.txt)
file(GLOB tsfiles *.ts)

QT4_ADD_TRANSLATION(QM ${tsfiles})

add_custom_target (release-translation ALL 
		DEPENDS ${QM}
		COMMENT "Compiling ts files"
)

install(FILES
	${txttrans2}
	${txttrans5}
	${QM}
	DESTINATION ${SHAREPATH}Data/Locale
)

