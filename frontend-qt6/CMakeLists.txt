cmake_minimum_required(VERSION 3.19)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

project(hedgewars LANGUAGES CXX)

find_package(PkgConfig REQUIRED)
pkg_check_modules(SDL2_MIXER REQUIRED IMPORTED_TARGET SDL2_mixer)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Widgets Network LinguistTools)
find_package(SDL2 REQUIRED CONFIG)

# --- Workaround Qt + CMake OpenGL::GL issue -------------------------------
# Qt's WrapOpenGL target exists, but OpenGL::GL imported target may not.
# Create a lightweight imported INTERFACE target that just forwards to WrapOpenGL.
if(TARGET WrapOpenGL::WrapOpenGL AND NOT TARGET OpenGL::GL)
    message(STATUS "Creating compatibility target OpenGL::GL -> WrapOpenGL::WrapOpenGL")
    add_library(OpenGL::GL INTERFACE IMPORTED)
    set_target_properties(OpenGL::GL PROPERTIES
        INTERFACE_LINK_LIBRARIES "WrapOpenGL::WrapOpenGL"
    )
endif()

# server messages localization
file(GLOB ServerSources ${CMAKE_CURRENT_SOURCE_DIR}/../gameServer/*.hs)
foreach(hsfile ${ServerSources})
    file(READ ${hsfile} hs)
    string(REGEX MATCHALL "loc *\"[^\n\"]+\"" locs ${hs})
    foreach(str ${locs})
        string(REGEX REPLACE "loc *\"([^\n\"]+)\"" "QT_TRANSLATE_NOOP(\"server\", \"\\1\")" s ${str})
        list(APPEND serverlocs ${s})
    endforeach(str)
endforeach(hsfile)

list(REMOVE_DUPLICATES serverlocs)
list(GET serverlocs 0 firstline)
list(REMOVE_AT serverlocs 0)
set(locsout "const char * serverMessages[] = {\n")
foreach(l ${serverlocs})
    list(APPEND locsout ${l} ",\n")
endforeach(l)
list(APPEND locsout ${firstline} "\n}\\;\n")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/servermessages.h ${locsout})


# Credits localization
file(GLOB CreditsCSV ${CMAKE_CURRENT_SOURCE_DIR}/res/credits.csv)
foreach(csvfile ${CreditsCSV})
    # Load credits.csv
    file(READ ${csvfile} csv)

    # Match first line of CSV file
    string(REGEX MATCH "(E|S|U),\"[^\n\"]+\"" loc_top ${csv})
    string(REGEX REPLACE "(E|S|U),\"([^\n\"]+)\"" "\nQT_TRANSLATE_NOOP(\"credits\", \"\\2\")" s ${loc_top})
    list(APPEND csvlocs ${s})

    # Match remaining lines of CSV file
    string(REGEX MATCHALL "\n(E|S|U),\"[^\n\"]+\"" locs ${csv})
    foreach(str ${locs})
        string(REGEX REPLACE "(E|S|U),\"([^\n\"]+)\"" "QT_TRANSLATE_NOOP(\"credits\", \"\\2\")" s ${str})
        list(APPEND csvlocs ${s})
    endforeach(str)
endforeach(csvfile)

list(REMOVE_DUPLICATES csvlocs)
list(GET csvlocs 0 firstline)
list(REMOVE_AT csvlocs 0)
set(locsout "const char * creditsMessages[] = {")
foreach(l ${csvlocs})
    list(APPEND locsout ${l} ",")
endforeach(l)
list(APPEND locsout ${firstline} "\n}\\;\n")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/creditsmessages.h ${locsout})


qt_standard_project_setup()

qt_add_executable(hedgewars
    WIN32 MACOSX_BUNDLE
    hedgewars.qrc

    achievements.cpp
    achievements.h
    binds.cpp
    binds.h
    campaign.cpp
    campaign.h
    drawmapscene.cpp
    drawmapscene.h
    game.cpp
    game.h
    gameuiconfig.cpp
    gameuiconfig.h
    HWApplication.cpp
    HWApplication.h
    hwconsts.cpp
    hwconsts.h
    hwform.cpp
    hwform.h
    hwform_ui.cpp
    hwform_ui.h
    main.cpp
    mission.cpp
    mission.h
    model/gameSchemeModel.cpp
    model/gameSchemeModel.h
    model/GameStyleModel.cpp
    model/GameStyleModel.h
    model/HatModel.cpp
    model/HatModel.h
    model/MapModel.cpp
    model/MapModel.h
    model/netserverslist.cpp
    model/netserverslist.h
    model/playerslistmodel.cpp
    model/playerslistmodel.h
    model/roomslistmodel.cpp
    model/roomslistmodel.h
    model/ThemeFilterProxyModel.cpp
    model/ThemeFilterProxyModel.h
    model/ThemeModel.cpp
    model/ThemeModel.h
    net/hwmap.cpp
    net/hwmap.h
    net/hwmapoptimizer.cpp
    net/hwmapoptimizer.h
    net/netregister.cpp
    net/netregister.h
    net/netserver.cpp
    net/netserver.h
    net/netudpserver.cpp
    net/netudpserver.h
    net/netudpwidget.cpp
    net/netudpwidget.h
    net/newnetclient.cpp
    net/newnetclient.h
    net/proto.cpp
    net/proto.h
    net/recorder.cpp
    net/recorder.h
    net/tcpBase.cpp
    net/tcpBase.h
    sdlkeys.cpp
    sdlkeys.h
    team.cpp
    team.h
    ui/dialog/ask_quit.cpp
    ui/dialog/ask_quit.h
    ui/dialog/bandialog.cpp
    ui/dialog/bandialog.h
    ui/dialog/input_ip.cpp
    ui/dialog/input_ip.h
    ui/dialog/input_password.cpp
    ui/dialog/input_password.h
    ui/mouseoverfilter.cpp
    ui/mouseoverfilter.h
    ui/page/AbstractPage.cpp
    ui/page/AbstractPage.h
    ui/page/pageadmin.cpp
    ui/page/pageadmin.h
    ui/page/pagecampaign.cpp
    ui/page/pagecampaign.h
    ui/page/pageconnecting.cpp
    ui/page/pageconnecting.h
    ui/page/pagedata.cpp
    ui/page/pagedata.h
    ui/page/pagedrawmap.cpp
    ui/page/pagedrawmap.h
    ui/page/pageeditteam.cpp
    ui/page/pageeditteam.h
    ui/page/pagegamestats.cpp
    ui/page/pagegamestats.h
    ui/page/pageinfo.cpp
    ui/page/pageinfo.h
    ui/page/pageingame.cpp
    ui/page/pageingame.h
    ui/page/pagemain.cpp
    ui/page/pagemain.h
    ui/page/pagemultiplayer.cpp
    ui/page/pagemultiplayer.h
    ui/page/pagenet.cpp
    ui/page/pagenetgame.cpp
    ui/page/pagenetgame.h
    ui/page/pagenet.h
    ui/page/pagenetserver.cpp
    ui/page/pagenetserver.h
    ui/page/pageoptions.cpp
    ui/page/pageoptions.h
    ui/page/pageplayrecord.cpp
    ui/page/pageplayrecord.h
    ui/page/pageroomslist.cpp
    ui/page/pageroomslist.h
    ui/page/pagescheme.cpp
    ui/page/pagescheme.h
    ui/page/pageselectweapon.cpp
    ui/page/pageselectweapon.h
    ui/page/pagesingleplayer.cpp
    ui/page/pagesingleplayer.h
    ui/page/pagetraining.cpp
    ui/page/pagetraining.h
    ui/page/pagevideos.cpp
    ui/page/pagevideos.h
    ui/widget/about.cpp
    ui/widget/about.h
    ui/widget/bgwidget.cpp
    ui/widget/bgwidget.h
    ui/widget/chatwidget.cpp
    ui/widget/chatwidget.h
    ui/widget/colorwidget.cpp
    ui/widget/colorwidget.h
    ui/widget/databrowser.cpp
    ui/widget/databrowser.h
    ui/widget/drawmapwidget.cpp
    ui/widget/drawmapwidget.h
    ui/widget/feedbackdialog.cpp
    ui/widget/feedbackdialog.h
    ui/widget/fpsedit.cpp
    ui/widget/fpsedit.h
    ui/widget/frameTeam.cpp
    ui/widget/frameTeam.h
    ui/widget/FreqSpinBox.cpp
    ui/widget/FreqSpinBox.h
    ui/widget/gamecfgwidget.cpp
    ui/widget/gamecfgwidget.h
    ui/widget/hatbutton.cpp
    ui/widget/hatbutton.h
    ui/widget/hatprompt.cpp
    ui/widget/hatprompt.h
    ui/widget/hedgehogerWidget.cpp
    ui/widget/hedgehogerWidget.h
    ui/widget/HistoryLineEdit.cpp
    ui/widget/HistoryLineEdit.h
    ui/widget/igbox.cpp
    ui/widget/igbox.h
    ui/widget/itemNum.cpp
    ui/widget/itemNum.h
    ui/widget/keybinder.cpp
    ui/widget/keybinder.h
    ui/widget/lineeditcursor.cpp
    ui/widget/lineeditcursor.h
    ui/widget/mapContainer.cpp
    ui/widget/mapContainer.h
    ui/widget/MinesTimeSpinBox.cpp
    ui/widget/MinesTimeSpinBox.h
    ui/widget/qpushbuttonwithsound.cpp
    ui/widget/qpushbuttonwithsound.h
    ui/widget/roomnameprompt.cpp
    ui/widget/roomnameprompt.h
    ui/widget/SDTimeoutSpinBox.cpp
    ui/widget/SDTimeoutSpinBox.h
    ui/widget/seedprompt.cpp
    ui/widget/seedprompt.h
    ui/widget/selectWeapon.cpp
    ui/widget/selectWeapon.h
    ui/widget/SmartLineEdit.cpp
    ui/widget/SmartLineEdit.h
    ui/widget/SquareLabel.cpp
    ui/widget/SquareLabel.h
    ui/widget/teamselect.cpp
    ui/widget/teamselect.h
    ui/widget/teamselhelper.cpp
    ui/widget/teamselhelper.h
    ui/widget/themeprompt.cpp
    ui/widget/themeprompt.h
    ui/widget/togglebutton.cpp
    ui/widget/togglebutton.h
    ui/widget/vertScrollArea.cpp
    ui/widget/vertScrollArea.h
    ui/widget/weaponItem.cpp
    ui/widget/weaponItem.h
    util/DataManager.cpp
    util/DataManager.h
    util/KeyMap.cpp
    util/KeyMap.h
    util/LibavInteraction.cpp
    util/LibavInteraction.h
    util/MessageDialog.cpp
    util/MessageDialog.h
    util/namegen.cpp
    util/namegen.h
    util/platform/AutoUpdater.cpp
    util/platform/AutoUpdater.h
    util/platform/CocoaInitializer.h
    util/platform/InstallController.cpp
    util/platform/InstallController.h
    util/platform/M3InstallController.h
    util/platform/M3Panel.h
    util/platform/NSWorkspace_RBAdditions.h
    util/platform/SparkleAutoUpdater.h
    util/SDLInteraction.cpp
    util/SDLInteraction.h
    weapons.h

    ${CMAKE_CURRENT_BINARY_DIR}/servermessages.h
    ${CMAKE_CURRENT_BINARY_DIR}/creditsmessages.h
)

target_compile_definitions(hedgewars PRIVATE
    HEDGEWARS_DATADIR="${HEDGEWARS_DATADIR}"
    HEDGEWARS_PROTO_VER="${HEDGEWARS_PROTO_VER}"
    HEDGEWARS_VERSION="${HEDGEWARS_VERSION}"
    HEDGEWARS_REVISION="${HEDGEWARS_REVISION}"
    HEDGEWARS_HASH="${HEDGEWARS_HASH}"
)

target_include_directories(hedgewars PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/model
    ${CMAKE_CURRENT_SOURCE_DIR}/net
    ${CMAKE_CURRENT_SOURCE_DIR}/ui
    ${CMAKE_CURRENT_SOURCE_DIR}/ui/dialog
    ${CMAKE_CURRENT_SOURCE_DIR}/ui/page
    ${CMAKE_CURRENT_SOURCE_DIR}/ui/widget
    ${CMAKE_CURRENT_SOURCE_DIR}/util
    ${CMAKE_CURRENT_SOURCE_DIR}/util/platform
    ${CMAKE_CURRENT_SOURCE_DIR}/../misc/libphyslayer
    ${CMAKE_CURRENT_BINARY_DIR}
)

#qt_add_translations(
#    TARGETS hedgewars
#    TS_FILES hedgewars_ru_RU.ts
#)

target_link_libraries(hedgewars
    PRIVATE
        Qt::Core
        Qt::Widgets
        Qt::Network
        SDL2::SDL2
        SDL2_mixer
        PkgConfig::SDL2_MIXER
        physlayer
)

include(GNUInstallDirs)

install(TARGETS hedgewars
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_app_script(
    TARGET hedgewars
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
)
install(SCRIPT ${deploy_script})
