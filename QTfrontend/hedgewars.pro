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
 	#CONFIG += x86 ppc x86_64 ppc64
}

QT += network svg xml

HEADERS += 	KB.h SDLs.h SquareLabel.h \
		about.h ammoSchemeModel.h \
		bgwidget.h binds.h \
		chatwidget.h \
		fpsedit.h frameTeam.h \
		game.h gamecfgwidget.h gameuiconfig.h \
		hats.h hedgehogerWidget.h hwconsts.h hwform.h hwmap.h \
		igbox.h input_ip.h itemNum.h \
		mapContainer.h misc.h \
		namegen.h netregister.h netserver.h netserverslist.h \
		netudpserver.h netudpwidget.h newnetclient.h \
		pages.h playrecordpage.h predefteams.h proto.h \
		sdlkeys.h selectWeapon.h statsPage.h \
		tcpBase.h team.h teamselect.h teamselhelper.h togglebutton.h \
		ui_hwform.h \
		vertScrollArea.h \
		weaponItem.h


SOURCES +=	SDLs.cpp SquareLabel.cpp \
		about.cpp ammoSchemeModel.cpp \
		bgwidget.cpp binds.cpp \
		chatwidget.cpp \
		fpsedit.cpp frameTeam.cpp \
		game.cpp gamecfgwidget.cpp gameuiconfig.cpp \
		hats.cpp hedgehogerWidget.cpp hwconsts.cpp hwform.cpp hwmap.cpp \
		igbox.cpp input_ip.cpp itemNum.cpp \
		main.cpp mapContainer.cpp misc.cpp \
		namegen.cpp netregister.cpp netserver.cpp netserverslist.cpp \
		netudpserver.cpp netudpwidget.cpp newnetclient.cpp \
		pages.cpp playrecordpage.cpp proto.cpp \
		selectWeapon.cpp statsPage.cpp \
		tcpBase.cpp team.cpp teamselect.cpp teamselhelper.cpp togglebutton.cpp \
		ui_hwform.cpp \
		vertScrollArea.cpp \
		weaponItem.cpp

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
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_pt_PT.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_ru.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_sk.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_sv.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_tr_TR.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_uk.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_zh_CN.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_zh_TW.ts

RESOURCES += hedgewars.qrc

!macx{
	LIBS += -lSDL -lopenalbridge
}else{
	LIBS += -framework SDL -framework OpenAL -framework Ogg -framework Vorbis -lopenalbridge -framework Sparkle
	INCLUDEPATH += /Library/Frameworks/SDL.framework/Headers
	SOURCES += AutoUpdater.cpp CocoaInitializer.mm SparkleAutoUpdater.mm
	HEADERS += AutoUpdater.h CocoaInitializer.h SparkleAutoUpdater.h
	
}
