find_package(Qt4 REQUIRED)

include_directories(${QT_INCLUDES} .)

set(hwfr_src 
	game.cpp
	main.cpp
	hwform.cpp 
	team.cpp
	rndstr.cpp
	sha1.cpp
	netclient.cpp
	teamselect.cpp
	teamselhelper.cpp
	frameTeam.cpp
	vertScrollArea.cpp
	gameconfig.cpp
	ui_hwform.cpp)

if (WIN32)
	set(hwfr_src ${hwfr_src} res/hedgewars.rc)
endif (WIN32)

set(hwfr_moc_hdrs
	game.h
	hwform.h
	netclient.h
	teamselect.h
	teamselhelper.h
	frameTeam.h
	vertScrollArea.h
	gameconfig.h
	ui_hwform.h)


set(hwfr_rez
	hedgewars.qrc)

qt4_add_resources(hwfr_rez_src
	${hwfr_rez})

qt4_wrap_cpp(hwfr_moc_srcs
	${hwfr_moc_hdrs})

add_executable(hedgewars WIN32
	${hwfr_src}
	${hwfr_moc_srcs}
	${hwfr_rez_src})

target_link_libraries(hedgewars 
	${QT_QTCORE_LIBRARY}
	${QT_QTGUI_LIBRARY}
	${QT_QTNETWORK_LIBRARY}
	${QT_QTMAIN_LIBRARY})

install_targets(/bin hedgewars)
