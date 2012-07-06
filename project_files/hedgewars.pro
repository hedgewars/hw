TEMPLATE = app
TARGET = hedgewars
DEPENDPATH += ../QTfrontend/
INCLUDEPATH += ../QTfrontend/
INCLUDEPATH += ../QTfrontend/model
INCLUDEPATH += ../QTfrontend/ui
INCLUDEPATH += ../QTfrontend/ui/widget
INCLUDEPATH += ../QTfrontend/ui/page
INCLUDEPATH += ../QTfrontend/ui/dialog
INCLUDEPATH += ../QTfrontend/net
INCLUDEPATH += ../QTfrontend/util
INCLUDEPATH += /usr/local/include/SDL
INCLUDEPATH += /usr/include/SDL
INCLUDEPATH += ../misc/quazip/

DESTDIR = .

win32 {
    RC_FILE = ../QTfrontend/hedgewars.rc
}

QT += network
QT += webkit

HEADERS += ../QTfrontend/model/ThemeModel.h \
    ../QTfrontend/model/MapModel.h \
    ../QTfrontend/model/ammoSchemeModel.h \
    ../QTfrontend/model/netserverslist.h \
    ../QTfrontend/ui/page/pagedrawmap.h \
    ../QTfrontend/ui/page/pagedata.h \
    ../QTfrontend/ui/page/pagetraining.h \
    ../QTfrontend/ui/page/pageselectweapon.h \
    ../QTfrontend/ui/page/pagesingleplayer.h \
    ../QTfrontend/ui/page/pagenettype.h \
    ../QTfrontend/ui/page/pageingame.h \
    ../QTfrontend/ui/page/pageadmin.h \
    ../QTfrontend/ui/page/pagescheme.h \
    ../QTfrontend/ui/page/pagemultiplayer.h \
    ../QTfrontend/ui/page/pageplayrecord.h \
    ../QTfrontend/ui/page/pagemain.h \
    ../QTfrontend/ui/page/pageoptions.h \
    ../QTfrontend/ui/page/pagenetgame.h \
    ../QTfrontend/ui/page/pageeditteam.h \
    ../QTfrontend/ui/page/pageconnecting.h \
    ../QTfrontend/ui/page/pageroomslist.h \
    ../QTfrontend/ui/page/pagenet.h \
    ../QTfrontend/ui/page/pagecampaign.h \
    ../QTfrontend/ui/page/pageinfo.h \
    ../QTfrontend/ui/page/pagenetserver.h \
    ../QTfrontend/ui/page/pagegamestats.h \
    ../QTfrontend/ui/dialog/input_ip.h \
    ../QTfrontend/ui/qaspectratiolayout.h \
    ../QTfrontend/ui/widget/bgwidget.h \
    ../QTfrontend/ui/widget/fpsedit.h \
    ../QTfrontend/ui/widget/FreqSpinBox.h \
    ../QTfrontend/ui/widget/igbox.h \
    ../QTfrontend/ui/widget/chatwidget.h \
    ../QTfrontend/ui/widget/togglebutton.h \
    ../QTfrontend/ui/widget/SquareLabel.h \
    ../QTfrontend/ui/widget/itemNum.h \
    ../QTfrontend/ui/widget/frameTeam.h \
    ../QTfrontend/ui/widget/teamselect.h \
    ../QTfrontend/ui/widget/vertScrollArea.h \
    ../QTfrontend/ui/widget/about.h \
    ../QTfrontend/ui/widget/teamselhelper.h \
    ../QTfrontend/ui/widget/drawmapwidget.h \
    ../QTfrontend/ui/widget/databrowser.h \
    ../QTfrontend/ui/widget/hedgehogerWidget.h \
    ../QTfrontend/ui/widget/selectWeapon.h \
    ../QTfrontend/ui/widget/weaponItem.h \
    ../QTfrontend/ui/widget/gamecfgwidget.h \
    ../QTfrontend/ui/widget/mapContainer.h \
    ../QTfrontend/ui/widget/HistoryLineEdit.h \
    ../QTfrontend/ui/widget/SmartLineEdit.h \
    ../QTfrontend/util/DataManager.h \
    ../QTfrontend/net/netregister.h \
    ../QTfrontend/net/netserver.h \
    ../QTfrontend/net/netudpwidget.h \
    ../QTfrontend/net/tcpBase.h \
    ../QTfrontend/net/proto.h \
    ../QTfrontend/net/newnetclient.h \
    ../QTfrontend/net/netudpserver.h \
    ../QTfrontend/net/hwmap.h \
    ../QTfrontend/util/namegen.h \
    ../QTfrontend/ui/page/AbstractPage.h \
    ../QTfrontend/drawmapscene.h \
    ../QTfrontend/game.h \
    ../QTfrontend/gameuiconfig.h \
    ../QTfrontend/HWApplication.h \
    ../QTfrontend/hwform.h \
    ../QTfrontend/util/SDLInteraction.h \
    ../QTfrontend/team.h \
    ../QTfrontend/achievements.h \
    ../QTfrontend/binds.h \
    ../QTfrontend/ui_hwform.h \
    ../QTfrontend/KB.h \
    ../QTfrontend/hwconsts.h \
    ../QTfrontend/sdlkeys.h \
    ../QTfrontend/ui/mouseoverfilter.h \
    ../QTfrontend/ui/qpushbuttonwithsound.h \
    ../QTfrontend/ui/widget/qpushbuttonwithsound.h \
    ../QTfrontend/ui/page/pagefeedback.h \
    ../QTfrontend/model/roomslistmodel.h \
    ../QTfrontend/ui/dialog/input_password.h \
    ../QTfrontend/ui/widget/colorwidget.h \
    ../QTfrontend/model/HatModel.h \
    ../QTfrontend/model/GameStyleModel.h \
    ../QTfrontend/util/libav_iteraction.h \
    ../QTfrontend/ui/page/pagevideos.h \
    ../QTfrontend/net/recorder.h \
    ../QTfrontend/ui/dialog/ask_quit.h

SOURCES += ../QTfrontend/model/ammoSchemeModel.cpp \
    ../QTfrontend/model/MapModel.cpp \
    ../QTfrontend/model/ThemeModel.cpp \
    ../QTfrontend/model/netserverslist.cpp \
    ../QTfrontend/ui/qaspectratiolayout.cpp \
    ../QTfrontend/ui/page/pagemain.cpp \
    ../QTfrontend/ui/page/pagetraining.cpp \
    ../QTfrontend/ui/page/pageroomslist.cpp \
    ../QTfrontend/ui/page/pagemultiplayer.cpp \
    ../QTfrontend/ui/page/pagegamestats.cpp \
    ../QTfrontend/ui/page/pagenettype.cpp \
    ../QTfrontend/ui/page/pageeditteam.cpp \
    ../QTfrontend/ui/page/pagenetgame.cpp \
    ../QTfrontend/ui/page/pagedata.cpp \
    ../QTfrontend/ui/page/pagedrawmap.cpp \
    ../QTfrontend/ui/page/pageplayrecord.cpp \
    ../QTfrontend/ui/page/pageselectweapon.cpp \
    ../QTfrontend/ui/page/pageingame.cpp \
    ../QTfrontend/ui/page/pagenetserver.cpp \
    ../QTfrontend/ui/page/pagecampaign.cpp \
    ../QTfrontend/ui/page/pageadmin.cpp \
    ../QTfrontend/ui/page/pageinfo.cpp \
    ../QTfrontend/ui/page/pageconnecting.cpp \
    ../QTfrontend/ui/page/pagesingleplayer.cpp \
    ../QTfrontend/ui/page/pagenet.cpp \
    ../QTfrontend/ui/page/pagescheme.cpp \
    ../QTfrontend/ui/page/pageoptions.cpp \
    ../QTfrontend/ui/dialog/input_ip.cpp \
    ../QTfrontend/ui/widget/igbox.cpp \
    ../QTfrontend/ui/widget/selectWeapon.cpp \
    ../QTfrontend/ui/widget/FreqSpinBox.cpp \
    ../QTfrontend/ui/widget/SquareLabel.cpp \
    ../QTfrontend/ui/widget/frameTeam.cpp \
    ../QTfrontend/ui/widget/fpsedit.cpp \
    ../QTfrontend/ui/widget/databrowser.cpp \
    ../QTfrontend/ui/widget/teamselect.cpp \
    ../QTfrontend/ui/widget/gamecfgwidget.cpp \
    ../QTfrontend/ui/widget/chatwidget.cpp \
    ../QTfrontend/ui/widget/itemNum.cpp \
    ../QTfrontend/ui/widget/bgwidget.cpp \
    ../QTfrontend/ui/widget/about.cpp \
    ../QTfrontend/ui/widget/togglebutton.cpp \
    ../QTfrontend/ui/widget/vertScrollArea.cpp \
    ../QTfrontend/ui/widget/hedgehogerWidget.cpp \
    ../QTfrontend/ui/widget/teamselhelper.cpp \
    ../QTfrontend/ui/widget/drawmapwidget.cpp \
    ../QTfrontend/ui/widget/weaponItem.cpp \
    ../QTfrontend/ui/widget/mapContainer.cpp \
    ../QTfrontend/ui/widget/HistoryLineEdit.cpp \
    ../QTfrontend/ui/widget/SmartLineEdit.cpp \
    ../QTfrontend/util/DataManager.cpp \
    ../QTfrontend/net/tcpBase.cpp \
    ../QTfrontend/net/netregister.cpp \
    ../QTfrontend/net/proto.cpp \
    ../QTfrontend/net/hwmap.cpp \
    ../QTfrontend/net/netudpserver.cpp \
    ../QTfrontend/net/newnetclient.cpp \
    ../QTfrontend/net/netudpwidget.cpp \
    ../QTfrontend/net/netserver.cpp \
    ../QTfrontend/util/namegen.cpp \
    ../QTfrontend/ui/page/AbstractPage.cpp \
    ../QTfrontend/achievements.cpp \
    ../QTfrontend/binds.cpp \
    ../QTfrontend/drawmapscene.cpp \
    ../QTfrontend/game.cpp \
    ../QTfrontend/gameuiconfig.cpp \
    ../QTfrontend/HWApplication.cpp \
    ../QTfrontend/hwform.cpp \
    ../QTfrontend/main.cpp \
    ../QTfrontend/util/SDLInteraction.cpp \
    ../QTfrontend/team.cpp \
    ../QTfrontend/ui_hwform.cpp \
    ../QTfrontend/hwconsts.cpp \
    ../QTfrontend/ui/mouseoverfilter.cpp \
    ../QTfrontend/ui/widget/qpushbuttonwithsound.cpp \
    ../QTfrontend/ui/page/pagefeedback.cpp \
    ../QTfrontend/model/roomslistmodel.cpp \
    ../QTfrontend/ui/dialog/input_password.cpp \
    ../QTfrontend/ui/widget/colorwidget.cpp \
    ../QTfrontend/model/HatModel.cpp \
    ../QTfrontend/model/GameStyleModel.cpp \
    ../QTfrontend/util/libav_iteraction.cpp \
    ../QTfrontend/ui/page/pagevideos.cpp \
    ../QTfrontend/net/recorder.cpp \
    ../QTfrontend/ui/dialog/ask_quit.cpp

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
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_ko.ts 	 
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_lt.ts
TRANSLATIONS += ../share/hedgewars/Data/Locale/hedgewars_nl.ts 	 
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

LIBS += -L../misc/quazip -lquazip

!macx {
    LIBS += -lSDL -lSDL_mixer
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

FORMS +=
