TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += .
INCLUDEPATH += .
DESTDIR	= ../bin

win32 {
	RC_FILE	= ./res/hedgewars.rc
}

QT += network

HEADERS += binds.h \
           game.h \
           hwform.h \
           sdlkeys.h \
           team.h \
           rndstr.h \
           sha1.h \
           netclient.h \
           teamselect.h \
           teamselhelper.h \
           frameTeam.h \
           vertScrollArea.h \
           gameuiconfig.h \
           ui_hwform.h \
           gamecfgwidget.h \
           predefteams.h \
           pages.h \
           SquareLabel.h
           
SOURCES += game.cpp \
           main.cpp \
           hwform.cpp \
           team.cpp \
           rndstr.cpp \
           sha1.cpp \
           netclient.cpp \
           teamselect.cpp \
           teamselhelper.cpp \
           frameTeam.cpp \
           vertScrollArea.cpp \
           gameuiconfig.cpp \
           ui_hwform.cpp \
           gamecfgwidget.cpp \
           pages.cpp \
           SquareLabel.cpp

TRANSLATIONS += translations/hedgewars_ru.ts

RESOURCES += hedgewars.qrc
