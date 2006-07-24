TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += .
INCLUDEPATH += .
DESTDIR	= ../hedgewars

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
           gameconfig.h \
           ui_hwform.h
           
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
           gameconfig.cpp \
           ui_hwform.cpp

TRANSLATIONS += translations/hedgewars_ru.ts

RESOURCES += hedgewars.qrc
