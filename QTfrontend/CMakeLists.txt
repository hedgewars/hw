# Configure for Qt4
set(QT_MIN_VERSION "4.2.0")

set(QT_USE_QTCORE TRUE)
set(QT_USE_QTGUI TRUE)
set(QT_USE_QTNETWORK TRUE)
set(QT_USE_QTSVG TRUE)
set(QT_USE_QTXML TRUE)
set(QT_USE_QTMAIN TRUE)

find_package(Qt4 REQUIRED)
include(${QT_USE_FILE}) 

# Configure for SDL
find_package(SDL REQUIRED)

include_directories(${SDL_INCLUDE_DIR})

# Done
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

configure_file(${hedgewars_SOURCE_DIR}/QTfrontend/hwconsts.cpp.in 
	${CMAKE_CURRENT_BINARY_DIR}/hwconsts.cpp)

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
	netwwwserver.cpp
	netwwwwidget.cpp
	netregister.cpp
	netserverslist.cpp
	chatwidget.cpp
	binds.cpp
	SDLs.cpp
	playrecordpage.cpp
	${CMAKE_CURRENT_BINARY_DIR}/hwconsts.cpp
	selectWeapon.cpp
	itemNum.cpp
	input_ip.cpp
	weaponItem.cpp)

if(MINGW)
	# resource compilation for mingw
	add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o
	COMMAND windres -I ${CMAKE_CURRENT_SOURCE_DIR}
	-i ${CMAKE_CURRENT_SOURCE_DIR}/hedgewars.rc
	-o ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o)
	set(hwfr_src ${hwfr_src} ${CMAKE_CURRENT_BINARY_DIR}/hedgewars_rc.o)
else(MINGW)
	set(hwfr_src ${hwfr_src} hedgewars.rc)
endif(MINGW)

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
	netwwwserver.h
	netwwwwidget.h
	netregister.h
	netserverslist.h
	chatwidget.h
	SDLs.h
	playrecordpage.h
	selectWeapon.h
	itemNum.h
	input_ip.h
	weaponItem.h)

set(hwfr_hdrs
	binds.h
	ui_hwform.h
	predefteams.h
	KB.h
	hwconsts.h
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
	
set(HW_LINK_LIBS 
	${QT_LIBRARIES}
	${SDL_LIBRARY}
	)

if(WIN32 AND NOT UNIX)
	if(NOT SDL_LIBRARY)
		set(HW_LINK_LIBS 
			${HW_LINK_LIBS}
			SDL
			)
	endif(NOT SDL_LIBRARY)

	set(HW_LINK_LIBS 
		${HW_LINK_LIBS}
		ole32
		oleaut32
		winspool
		uuid
		)
endif(WIN32 AND NOT UNIX)

target_link_libraries(hedgewars
	${HW_LINK_LIBS})

install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION bin)
