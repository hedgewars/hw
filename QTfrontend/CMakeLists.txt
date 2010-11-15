# Configure for Qt4
set(QT_MIN_VERSION "4.5.0")

set(QT_USE_QTCORE TRUE)
set(QT_USE_QTGUI TRUE)
set(QT_USE_QTNETWORK TRUE)
set(QT_USE_QTSVG FALSE)
set(QT_USE_QTXML FALSE)
set(QT_USE_QTOPENGL FALSE)
set(QT_USE_QTMAIN TRUE)

find_package(Qt4 REQUIRED)
include(${QT_USE_FILE})

#find_package(QCA2 REQUIRED)
#include_directories(${QCA2_INCLUDE_DIR})

# Configure for SDL
find_package(SDL REQUIRED)
find_package(SDL_mixer REQUIRED)

include_directories(.)
include_directories(${SDL_INCLUDE_DIR})
include_directories(${SDLMIXER_INCLUDE_DIR})
if(UNIX)
	# HACK: in freebsd cannot find iconv.h included via SDL.h
	include_directories("/usr/local/include")
endif(UNIX)


if(WIN32 AND NOT UNIX)
	set(HEDGEWARS_BINDIR ".")
	set(HEDGEWARS_DATADIR "../share/")
        add_definitions(-DUSE_XFIRE)
else()
	set(HEDGEWARS_BINDIR ${CMAKE_INSTALL_PREFIX})
	if(DEFINED DATA_INSTALL_DIR)
		set(HEDGEWARS_DATADIR ${DATA_INSTALL_DIR})
	else()
		set(HEDGEWARS_DATADIR ${CMAKE_INSTALL_PREFIX}/share/)
	endif()
endif()


configure_file(${CMAKE_CURRENT_SOURCE_DIR}/hwconsts.cpp.in ${CMAKE_CURRENT_BINARY_DIR}/hwconsts.cpp)

set(	hwfr_src
	game.cpp
	main.cpp
	hwform.cpp
	team.cpp
	namegen.cpp
	teamselect.cpp
	teamselhelper.cpp
	frameTeam.cpp
	vertScrollArea.cpp
	gameuiconfig.cpp
	ui_hwform.cpp
	gamecfgwidget.cpp
	pages.cpp
	SquareLabel.cpp
	hats.cpp
	hedgehogerWidget.cpp
	hwmap.cpp
	mapContainer.cpp
	tcpBase.cpp
	about.cpp
	proto.cpp
	fpsedit.cpp
	netserver.cpp
	newnetclient.cpp
	netudpserver.cpp
	netudpwidget.cpp
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
	igbox.cpp
	weaponItem.cpp
	statsPage.cpp
	misc.cpp
	ammoSchemeModel.cpp
	togglebutton.cpp
	bgwidget.cpp
	achievements.cpp
	)

#xfire integration
if(WIN32)
	set(hwfr_src ${hwfr_src} xfire.cpp ../misc/xfire/xfiregameclient.cpp)
endif(WIN32)

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

set(	hwfr_moc_hdrs
	game.h
	hats.h
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
	newnetclient.h
	netudpserver.h
	netudpwidget.h
	netregister.h
	netserverslist.h
	chatwidget.h
	SDLs.h
	playrecordpage.h
	selectWeapon.h
	itemNum.h
	input_ip.h
	igbox.h
	weaponItem.h
	statsPage.h
	misc.h
	ammoSchemeModel.h
	togglebutton.h
	bgwidget.h
	)

set(	hwfr_hdrs
	binds.h
	ui_hwform.h
	predefteams.h
	KB.h
	hwconsts.h
	)

set(hwfr_rez hedgewars.qrc)

qt4_add_resources(hwfr_rez_src ${hwfr_rez})

qt4_wrap_cpp(hwfr_moc_srcs ${hwfr_moc_hdrs})


if(APPLE)
	set(hwfr_src ${hwfr_src} InstallController.cpp CocoaInitializer.mm M3Panel.mm M3InstallController.m NSWorkspace_RBAdditions.m)
	set(HW_LINK_LIBS IOKit)

	find_package(Sparkle)
	if(SPARKLE_FOUND)
                add_definitions(-DSPARKLE_ENABLED)
		set(hwfr_src ${hwfr_src} AutoUpdater.cpp SparkleAutoUpdater.mm)
                set(HW_LINK_LIBS ${SPARKLE_LIBRARY} ${HW_LINK_LIBS})
	endif()
endif()


add_executable(hedgewars WIN32
	${hwfr_src}
	${hwfr_moc_srcs}
	${hwfr_hdrs}
	${hwfr_rez_src}
	)


set(	HW_LINK_LIBS
	${QT_LIBRARIES}
	${SDL_LIBRARY}
	${SDLMIXER_LIBRARY}
	${HW_LINK_LIBS}
	)

if(WIN32 AND NOT UNIX)
	if(NOT SDL_LIBRARY)
		set(HW_LINK_LIBS ${HW_LINK_LIBS} SDL)
	endif()

	set(	HW_LINK_LIBS
		${HW_LINK_LIBS}
		ole32
		oleaut32
		winspool
		uuid
		)
endif()


target_link_libraries(hedgewars	${HW_LINK_LIBS})


install(PROGRAMS "${EXECUTABLE_OUTPUT_PATH}/hedgewars${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION ${target_dir})

