TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += ../QTfrontend/
INCLUDEPATH += ../QTfrontend/
DESTDIR = .

win32 {
	RC_FILE	= ../QTfrontend/res/hedgewars.rc
}

QT += network

HEADERS += ../QTfrontend/KB.h ../QTfrontend/SDLs.h \
	../QTfrontend/SquareLabel.h ../QTfrontend/about.h \
	../QTfrontend/ammoSchemeModel.h ../QTfrontend/bgwidget.h \
	../QTfrontend/binds.h ../QTfrontend/chatwidget.h \
	../QTfrontend/fpsedit.h ../QTfrontend/frameTeam.h \
	../QTfrontend/game.h ../QTfrontend/gamecfgwidget.h \
	../QTfrontend/gameuiconfig.h ../QTfrontend/hats.h \
	../QTfrontend/hedgehogerWidget.h ../QTfrontend/hwconsts.h \
	../QTfrontend/hwform.h ../QTfrontend/hwmap.h \
	../QTfrontend/igbox.h ../QTfrontend/input_ip.h \
	../QTfrontend/itemNum.h ../QTfrontend/mapContainer.h \
	../QTfrontend/misc.h ../QTfrontend/namegen.h \
	../QTfrontend/netregister.h ../QTfrontend/netserver.h \
	../QTfrontend/netserverslist.h ../QTfrontend/netudpserver.h \
	../QTfrontend/netudpwidget.h ../QTfrontend/newnetclient.h \
	../QTfrontend/pages.h ../QTfrontend/playrecordpage.h \
	../QTfrontend/predefteams.h ../QTfrontend/proto.h \
	../QTfrontend/sdlkeys.h ../QTfrontend/selectWeapon.h \
	../QTfrontend/statsPage.h ../QTfrontend/tcpBase.h \
	../QTfrontend/team.h ../QTfrontend/teamselect.h \
	../QTfrontend/teamselhelper.h ../QTfrontend/togglebutton.h \
	../QTfrontend/ui_hwform.h ../QTfrontend/vertScrollArea.h \
	../QTfrontend/weaponItem.h ../QTfrontend/xfire.h \
	../QTfrontend/achievements.h

SOURCES += ../QTfrontend/SDLs.cpp ../QTfrontend/SquareLabel.cpp \
	../QTfrontend/about.cpp ../QTfrontend/ammoSchemeModel.cpp \
	../QTfrontend/bgwidget.cpp ../QTfrontend/binds.cpp \
	../QTfrontend/chatwidget.cpp ../QTfrontend/fpsedit.cpp \
	../QTfrontend/frameTeam.cpp ../QTfrontend/game.cpp \
	../QTfrontend/gamecfgwidget.cpp ../QTfrontend/gameuiconfig.cpp \
	../QTfrontend/hats.cpp ../QTfrontend/hedgehogerWidget.cpp \
	../QTfrontend/hwform.cpp ../QTfrontend/hwmap.cpp \
	../QTfrontend/igbox.cpp ../QTfrontend/input_ip.cpp \
	../QTfrontend/itemNum.cpp ../QTfrontend/main.cpp \
	../QTfrontend/mapContainer.cpp ../QTfrontend/misc.cpp \
	../QTfrontend/namegen.cpp ../QTfrontend/netregister.cpp \
	../QTfrontend/netserver.cpp ../QTfrontend/netserverslist.cpp \
	../QTfrontend/netudpserver.cpp ../QTfrontend/netudpwidget.cpp \
	../QTfrontend/newnetclient.cpp ../QTfrontend/pages.cpp \
	../QTfrontend/playrecordpage.cpp ../QTfrontend/proto.cpp \
	../QTfrontend/selectWeapon.cpp ../QTfrontend/statsPage.cpp \
	../QTfrontend/tcpBase.cpp ../QTfrontend/team.cpp \
	../QTfrontend/teamselect.cpp ../QTfrontend/teamselhelper.cpp \
	../QTfrontend/togglebutton.cpp ../QTfrontend/ui_hwform.cpp \
	../QTfrontend/vertScrollArea.cpp ../QTfrontend/weaponItem.cpp \
	../QTfrontend/achievements.cpp

win32 {
	SOURCES += ../QTfrontend/xfire.cpp
}

TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_ar.ts 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_bg.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_cs.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_de.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_en.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_es.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_fi.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_fr.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_hu.ts 	 
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

RESOURCES += ../QTfrontend/hedgewars.qrc

!macx {
	LIBS += -lSDL -lSDL_Mixer
} else {
	QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.6
	QMAKE_MAC_SDK=/Developer/SDKs/MacOSX10.6.sdk
	
	OBJECTIVE_SOURCES += ../QTfrontend/*.m ../QTfrontend/*.mm 
	SOURCES += ../QTfrontend/AutoUpdater.cpp ../QTfrontend/InstallController.cpp \
			../../build/QTfrontend/hwconsts.cpp
	HEADERS += ../QTfrontend/M3InstallController.h ../QTfrontend/M3Panel.h \
		../QTfrontend/NSWorkspace_RBAdditions.h ../QTfrontend/AutoUpdater.h \
		../QTfrontend/CocoaInitializer.h ../QTfrontend/InstallController.h \
		../QTfrontend/SparkleAutoUpdater.h 
	
	LIBS += -lobjc -framework AppKit -framework IOKit -framework Foundation -framework SDL -framework SDL_Mixer -framework Sparkle -DSPARKLE_ENABLED 
	INCLUDEPATH += /Library/Frameworks/SDL.framework/Headers /Library/Frameworks/SDL_Mixer.framework/Headers
	CONFIG += warn_on x86

 	#CONFIG += x86 ppc x86_64 ppc64
}
