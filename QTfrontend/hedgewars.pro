TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += .
INCLUDEPATH += .
DESTDIR = ../bin

win32 {
	RC_FILE	= ./res/hedgewars.rc
}

macx{
	CONFIG += x86
}
QT += network svg xml

HEADERS += binds.h \
		game.h \
		hwform.h \
		sdlkeys.h \
		team.h \
		teamselect.h \
		teamselhelper.h \
		frameTeam.h \
		vertScrollArea.h \
		gameuiconfig.h \
		ui_hwform.h \
		gamecfgwidget.h \
		predefteams.h \
		pages.h \
		SquareLabel.h \
		hedgehogerWidget.h \
		hwmap.h \
		mapContainer.h \
		tcpBase.h \
		about.h \
		KB.h \
		proto.h \
		fpsedit.h \
		netserver.h \
		newnetclient.h \
		netudpserver.h \
		netudpwidget.h \
		netserverslist.h \
		chatwidget.h \
		SDLs.h \
		playrecordpage.h \
		hwconsts.h \
		selectWeapon.h \
		itemNum.h \
		input_ip.h \
		igbox.h \
		weaponItem.h \
		statsPage.h \
		misc.h

SOURCES += binds.cpp \
		game.cpp \
		main.cpp \
		hwform.cpp \
		team.cpp \
		teamselect.cpp \
		teamselhelper.cpp \
		frameTeam.cpp \
		vertScrollArea.cpp \
		gameuiconfig.cpp \
		ui_hwform.cpp \
		gamecfgwidget.cpp \
		pages.cpp \
		SquareLabel.cpp \
		hedgehogerWidget.cpp \
		hwmap.cpp \
		mapContainer.cpp \
		tcpBase.cpp \
		about.cpp \
		proto.cpp \
		fpsedit.cpp \
		netserver.cpp \
		newnetclient.cpp \
		netudpserver.cpp \
		netudpwidget.cpp \
		netserverslist.cpp \
		chatwidget.cpp \
		SDLs.cpp \
		playrecordpage.cpp \
		hwconsts.cpp \
		selectWeapon.cpp \
		itemNum.cpp \
		input_ip.cpp \
		igbox.cpp \
		weaponItem.cpp \
		statsPage.cpp \
		misc.cpp

TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_bg.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_de.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_cs.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_en.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_es.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_fi.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_fr.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_it.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_ja.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_pl.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_pt_BR.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_ru.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_sk.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_sv.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_tr_TR.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_uk.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_zh_CN.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_zh_TW.ts

RESOURCES += hedgewars.qrc

!macx{
LIBS += libSDL
}else{
LIBS += -framework SDL -framework SDL_mixer -framework Ogg -framework Vorbis
}
