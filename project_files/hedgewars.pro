TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += ../QTfrontend/
INCLUDEPATH += ../QTfrontend/
DESTDIR = .

win32 {
	RC_FILE	= ../QTfrontend/res/hedgewars.rc
}

QT += network svg xml

HEADERS += ../QTfrontend/*.h
SOURCES += ../QTfrontend/*.cpp
TRANSLATIONS += ../share/hedgewars/Data/Locale/*.ts
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

	hedgewars.commands = echo "REMEMBER TO INSERT hwconst.cpp IN SOURCE DIRECTORY"
 	#CONFIG += x86 ppc x86_64 ppc64
}
