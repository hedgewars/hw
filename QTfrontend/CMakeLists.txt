set(QT_MIN_VERSION "4.2.0")

set(QT_USE_QTNETWORK TRUE)
set(QT_USE_QTSVG TRUE)
set(QT_USE_QTMAIN TRUE)

find_package(Qt4 REQUIRED)
include(${QT_USE_FILE}) 

include_directories(.)

if(WIN32 AND NOT UNIX)
	set(HEDGEWARS_BINDIR ".")
	set(HEDGEWARS_DATADIR "../share/")
else(WIN32 AND NOT UNIX)
	set(HEDGEWARS_BINDIR ${CMAKE_INSTALL_PREFIX})
	if(DEFINED DATA_INSTALL_DIR)
		set(HEDGEWARS_DATADIR ${DATA_INSTALL_DIR})
	else(DEFINED DATA_INSTALL_DIR)
		set(HEDGEWARS_DATADIR ${CMAKE_INSTALL_PREFIX}/share/)
	endif(DEFINED DATA_INSTALL_DIR)
endif(WIN32 AND NOT UNIX)

configure_file(${hedgewars_SOURCE_DIR}/QTfrontend/main.cpp.in 
	${hedgewars_SOURCE_DIR}/QTfrontend/main.cpp)
configure_file(${hedgewars_SOURCE_DIR}/QTfrontend/hwconsts.h.in 
	${hedgewars_SOURCE_DIR}/QTfrontend/hwconsts.h)

set(hwfr_src 
	game.cpp
	main.cpp
	hwform.cpp 
	team.cpp
	teamselect.cpp
	teamselhelper.cpp
	frameTeam.cpp
	vertScrollArea.cpp
	gameuiconfig.cpp
	ui_hwform.cpp
	gamecfgwidget.cpp
	pages.cpp
	SquareLabel.cpp
	hedgehogerWidget.cpp
	hwmap.cpp
	mapContainer.cpp
	tcpBase.cpp
	about.cpp
	proto.cpp
	fpsedit.cpp
	netserver.cpp
	netconnectedclient.cpp
	newnetclient.cpp
	netudpserver.cpp
	netudpwidget.cpp
	chatwidget.cpp)

if (WIN32)
	set(hwfr_src ${hwfr_src} res/hedgewars.rc)
endif (WIN32)

set(hwfr_moc_hdrs
	game.h
	hwform.h
	teamselect.h
	teamselhelper.h
	frameTeam.h
	vertScrollArea.h
	gameuiconfig.h
	gamecfgwidget.h
	pages.h
	SquareLabel.h
	hedgehogerWidget.h
	hwmap.h
	mapContainer.h
	tcpBase.h
	about.h
	proto.h
	fpsedit.h
	netserver.h
	netconnectedclient.h
	newnetclient.h
	netudpserver.h
	netudpwidget.h
	chatwidget.h)

set(hwfr_hdrs
	binds.h
	ui_hwform.h
	predefteams.h
	KB.h
)

set(hwfr_rez
	hedgewars.qrc)

qt4_add_resources(hwfr_rez_src
	${hwfr_rez})

qt4_wrap_cpp(hwfr_moc_srcs
	${hwfr_moc_hdrs})

add_executable(hedgewars WIN32
	${hwfr_src}
	${hwfr_moc_srcs}
	${hwfr_hdrs}
	${hwfr_rez_src})

target_link_libraries(hedgewars 
	${QT_LIBRARIES})

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION bin)


if(WIN32 AND NOT UNIX)
	string(REPLACE "\\" "/" QT_BIN_DIR $ENV{QTDIR}/bin)

	install(FILES
		"${QT_BIN_DIR}/QtNetwork4.dll"
		"${QT_BIN_DIR}/QtGui4.dll"
		"${QT_BIN_DIR}/QtCore4.dll"
		"${QT_BIN_DIR}/QtSvg4.dll"
		"${QT_BIN_DIR}/QtXml4.dll"
		"${QT_BIN_DIR}/mingwm10.dll"
		DESTINATION bin)
endif(WIN32 AND NOT UNIX)
