TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += ../QTfrontend/
INCLUDEPATH += ../QTfrontend/
DESTDIR = .

win32 {
	RC_FILE	= ../QTfrontend/res/hedgewars.rc
}

QT += network

HEADERS += ../QTfrontend/*.h
SOURCES += ../QTfrontend/*.cpp

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

RESOURCES += ../QTfrontend/hedgewars.qrc

!macx {
	LIBS += -lSDL -lSDL_Mixer
} else {
	QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.4
	QMAKE_MAC_SDK=/Developer/SDKs/MacOSX10.4u.sdk
	
	OBJECTIVE_SOURCES= ../QTfrontend/*.m ../QTfrontend/*.mm

	LIBS += -framework IOKit -framework SDL -framework SDL_Mixer -framework Sparkle -DSPARKLE_ENABLED 
	INCLUDEPATH += /Library/Frameworks/SDL.framework/Headers /Library/Frameworks/SDL_Mixer.framework/Headers
	CONFIG += warn_on x86

 	#CONFIG += x86 ppc x86_64 ppc64
}
