#include <QLibrary>
#include <QtQml>
#include <QDebug>
#include <QPainter>
#include <QUuid>

#include "hwengine.h"
#include "previewimageprovider.h"
#include "themeiconprovider.h"

extern "C" {
    RunEngine_t *flibRunEngine;
    registerUIMessagesCallback_t *flibRegisterUIMessagesCallback;
    setSeed_t *flibSetSeed;
    getSeed_t *flibGetSeed;
    setTheme_t *flibSetTheme;
    setScript_t *flibSetScript;
    setScheme_t *flibSetScheme;
    setAmmo_t *flibSetAmmo;
    getPreview_t *flibGetPreview;
    runQuickGame_t *flibRunQuickGame;
    runLocalGame_t *flibRunLocalGame;
    flibInit_t *flibInit;
    flibFree_t *flibFree;
    resetGameConfig_t * flibResetGameConfig;
    getThemesList_t *flibGetThemesList;
    freeThemesList_t *flibFreeThemesList;
    getThemeIcon_t *flibGetThemeIcon;
    getScriptsList_t *flibGetScriptsList;
    getSchemesList_t *flibGetSchemesList;
    getAmmosList_t *flibGetAmmosList;
    getTeamsList_t *flibGetTeamsList;
    tryAddTeam_t * flibTryAddTeam;
    tryRemoveTeam_t * flibTryRemoveTeam;
    changeTeamColor_t * flibChangeTeamColor;

    connectOfficialServer_t * flibConnectOfficialServer;
    passNetData_t * flibPassNetData;
    passFlibEvent_t * flibPassFlibEvent;
    sendChatLine_t * flibSendChatLine;
    joinRoom_t * flibJoinRoom;
    partRoom_t * flibPartRoom;
}

Q_DECLARE_METATYPE(MessageType)

HWEngine::HWEngine(QQmlEngine *engine, QObject *parent) :
    QObject(parent),
    m_engine(engine)
{
    qRegisterMetaType<MessageType>("MessageType");

    QLibrary hwlib("./libhwengine.so");

    if(!hwlib.load())
        qWarning() << "Engine library not found" << hwlib.errorString();

    flibRunEngine = (RunEngine_t*) hwlib.resolve("RunEngine");
    flibRegisterUIMessagesCallback = (registerUIMessagesCallback_t*) hwlib.resolve("registerUIMessagesCallback");
    flibGetSeed = (getSeed_t*) hwlib.resolve("getSeed");
    flibGetPreview = (getPreview_t*) hwlib.resolve("getPreview");
    flibRunQuickGame = (runQuickGame_t*) hwlib.resolve("runQuickGame");
    flibRunLocalGame = (runLocalGame_t*) hwlib.resolve("runLocalGame");
    flibInit = (flibInit_t*) hwlib.resolve("flibInit");
    flibFree = (flibFree_t*) hwlib.resolve("flibFree");

    flibSetSeed = (setSeed_t*) hwlib.resolve("setSeed");
    flibSetTheme = (setTheme_t*) hwlib.resolve("setTheme");
    flibSetScript = (setScript_t*) hwlib.resolve("setScript");
    flibSetScheme = (setScheme_t*) hwlib.resolve("setScheme");
    flibSetAmmo = (setAmmo_t*) hwlib.resolve("setAmmo");

    flibGetThemesList = (getThemesList_t*) hwlib.resolve("getThemesList");
    flibFreeThemesList = (freeThemesList_t*) hwlib.resolve("freeThemesList");
    flibGetThemeIcon = (getThemeIcon_t*) hwlib.resolve("getThemeIcon");

    flibGetScriptsList = (getScriptsList_t*) hwlib.resolve("getScriptsList");
    flibGetSchemesList = (getSchemesList_t*) hwlib.resolve("getSchemesList");
    flibGetAmmosList = (getAmmosList_t*) hwlib.resolve("getAmmosList");

    flibResetGameConfig = (resetGameConfig_t*) hwlib.resolve("resetGameConfig");
    flibGetTeamsList = (getTeamsList_t*) hwlib.resolve("getTeamsList");
    flibTryAddTeam = (tryAddTeam_t*) hwlib.resolve("tryAddTeam");
    flibTryRemoveTeam = (tryRemoveTeam_t*) hwlib.resolve("tryRemoveTeam");
    flibChangeTeamColor = (changeTeamColor_t*) hwlib.resolve("changeTeamColor");

    flibConnectOfficialServer = (connectOfficialServer_t*) hwlib.resolve("connectOfficialServer");
    flibPassNetData = (passNetData_t*) hwlib.resolve("passNetData");
    flibPassFlibEvent = (passFlibEvent_t*) hwlib.resolve("passFlibEvent");
    flibSendChatLine = (sendChatLine_t*) hwlib.resolve("sendChatLine");
    flibJoinRoom = (joinRoom_t*) hwlib.resolve("joinRoom");
    flibPartRoom = (partRoom_t*) hwlib.resolve("partRoom");

    flibInit("/usr/home/unC0Rr/Sources/Hedgewars/Hedgewars-GC/share/hedgewars/Data", "/usr/home/unC0Rr/.hedgewars");
    flibRegisterUIMessagesCallback(this, &guiMessagesCallback);

    ThemeIconProvider * themeIcon = (ThemeIconProvider *)m_engine->imageProvider(QLatin1String("theme"));
    themeIcon->setFileContentsFunction(flibGetThemeIcon);

    fillModels();
}

HWEngine::~HWEngine()
{
    flibFree();
}

void HWEngine::getPreview()
{
    flibSetSeed(QUuid::createUuid().toString().toLatin1());
    flibGetPreview();
}

void HWEngine::runQuickGame()
{
    flibSetSeed(QUuid::createUuid().toString().toLatin1());
    flibRunQuickGame();
}

void HWEngine::runLocalGame()
{
    flibRunLocalGame();
}


static QObject *hwengine_singletontype_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(scriptEngine)

    HWEngine *hwengine = new HWEngine(engine);
    return hwengine;
}

void HWEngine::exposeToQML()
{
    qDebug("HWEngine::exposeToQML");
    qmlRegisterSingletonType<HWEngine>("Hedgewars.Engine", 1, 0, "HWEngine", hwengine_singletontype_provider);
}


void HWEngine::guiMessagesCallback(void *context, MessageType mt, const char * msg, uint32_t len)
{
    HWEngine * obj = (HWEngine *)context;
    QByteArray b = QByteArray(msg, len);

    //qDebug() << "FLIPC in" << mt << " size = " << b.size();

    QMetaObject::invokeMethod(obj, "engineMessageHandler", Qt::QueuedConnection, Q_ARG(MessageType, mt), Q_ARG(QByteArray, b));
}

void HWEngine::engineMessageHandler(MessageType mt, const QByteArray &msg)
{
    switch(mt)
    {
    case MSG_RENDERINGPREVIEW: {
        emit previewIsRendering();
        break;
    }
    case MSG_PREVIEW: {
        PreviewImageProvider * preview = (PreviewImageProvider *)m_engine->imageProvider(QLatin1String("preview"));
        preview->setPixmap(msg);
        emit previewImageChanged();
        break;
    }
    case MSG_ADDPLAYINGTEAM: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit playingTeamAdded(l[1], l[0].toInt(), true);
        break;
    }
    case MSG_REMOVEPLAYINGTEAM: {
        emit playingTeamRemoved(QString::fromUtf8(msg));
        break;
    }
    case MSG_ADDTEAM: {
        emit localTeamAdded(QString::fromUtf8(msg), 0);
        break;
    }
    case MSG_REMOVETEAM: {
        emit localTeamRemoved(QString::fromUtf8(msg));
        break;
    }
    case MSG_TEAMCOLOR: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit teamColorChanged(l[0], QColor::fromRgba(l[1].toInt()).name());
        break;
    }
    case MSG_NETDATA: {
        flibPassNetData(msg.constData());
        break;
    }
    case MSG_FLIBEVENT: {
        flibPassFlibEvent(msg.constData());
        break;
    }
    case MSG_CONNECTED: {
        emit netConnected();
        break;
    }
    case MSG_DISCONNECTED: {
        emit netDisconnected(QString::fromUtf8(msg));
        break;
    }
    case MSG_ADDLOBBYCLIENT: {
        emit lobbyClientAdded(QString::fromUtf8(msg));
        break;
    }
    case MSG_REMOVELOBBYCLIENT: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit lobbyClientRemoved(l[0], l[1]);
        break;
    }
    case MSG_LOBBYCHATLINE: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit lobbyChatLine(l[0], l[1]);
        break;
    }
    case MSG_ADDROOMCLIENT: {
        emit roomClientAdded(QString::fromUtf8(msg));
        break;
    }
    case MSG_REMOVEROOMCLIENT: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit roomClientRemoved(l[0], l[1]);
        break;
    }
    case MSG_ROOMCHATLINE: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit roomChatLine(l[0], l[1]);
        break;
    }
    case MSG_ADDROOM: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit roomAdded(0, l[1], l[2].toInt(), l[3].toInt(), l[4], l[5], l[6], l[7], l[8]);
        break;
    }
    case MSG_UPDATEROOM: {
        QStringList l = QString::fromUtf8(msg).split('\n');
        emit roomUpdated(l[0], 0, l[2], l[3].toInt(), l[4].toInt(), l[5], l[6], l[7], l[8], l[9]);
        break;
    }
    case MSG_REMOVEROOM: {
        emit roomRemoved(QString::fromUtf8(msg));
        break;
    }
    case MSG_ERROR: {
        emit errorMessage(QString::fromUtf8(msg));
        break;
    }
    case MSG_WARNING: {
        emit warningMessage(QString::fromUtf8(msg));
        break;
    }
    case MSG_MOVETOLOBBY: {
        emit movedToLobby();
        break;
    }
    case MSG_MOVETOROOM: {
        emit movedToRoom();
        break;
    }
    case MSG_NICKNAME: {
        m_myNickname = QString::fromUtf8(msg);
        break;
    }
    case MSG_SEED: {
        emit seedChanged(QString::fromUtf8(msg));
        break;
    }
    case MSG_THEME: {
        emit themeChanged(QString::fromUtf8(msg));
        break;
    }
    case MSG_SCRIPT: {
        emit scriptChanged(QString::fromUtf8(msg));
        break;
    }
    case MSG_FEATURESIZE: {
        emit featureSizeChanged(msg.toInt());
        break;
    }
    case MSG_MAPGEN: {
        emit mapGenChanged(msg.toInt());
        break;
    }
    case MSG_MAP: {
        emit mapChanged(QString::fromUtf8(msg));
        break;
    }
    case MSG_MAZESIZE: {
        emit mazeSizeChanged(msg.toInt());
        break;
    }
    case MSG_TEMPLATE: {
        emit templateChanged(msg.toInt());
        break;
    }
    }
}

QString HWEngine::currentSeed()
{
    return QString::fromLatin1(flibGetSeed());
}

void HWEngine::fillModels()
{
    QStringList resultModel;

    char ** themes = flibGetThemesList();
    for (char **i = themes; *i != NULL; i++)
        resultModel << QString::fromUtf8(*i);
    flibFreeThemesList(themes);

    m_engine->rootContext()->setContextProperty("themesModel", QVariant::fromValue(resultModel));

    // scripts model
    resultModel.clear();
    for (char **i = flibGetScriptsList(); *i != NULL; i++)
        resultModel << QString::fromUtf8(*i);

    m_engine->rootContext()->setContextProperty("scriptsModel", QVariant::fromValue(resultModel));

    // schemes model
    resultModel.clear();
    for (char **i = flibGetSchemesList(); *i != NULL; i++)
        resultModel << QString::fromUtf8(*i);

    m_engine->rootContext()->setContextProperty("schemesModel", QVariant::fromValue(resultModel));

    // ammos model
    resultModel.clear();
    for (char **i = flibGetAmmosList(); *i != NULL; i++)
        resultModel << QString::fromUtf8(*i);

    m_engine->rootContext()->setContextProperty("ammosModel", QVariant::fromValue(resultModel));
}

void HWEngine::getTeamsList()
{
    char ** teams = flibGetTeamsList();
    for (char **i = teams; *i != NULL; i++) {
        QString team = QString::fromUtf8(*i);

        emit localTeamAdded(team, 0);
    }
}

void HWEngine::tryAddTeam(const QString &teamName)
{
    flibTryAddTeam(teamName.toUtf8().constData());
}

void HWEngine::tryRemoveTeam(const QString &teamName)
{
    flibTryRemoveTeam(teamName.toUtf8().constData());
}

void HWEngine::resetGameConfig()
{
    flibResetGameConfig();
}

void HWEngine::changeTeamColor(const QString &teamName, int dir)
{
    flibChangeTeamColor(teamName.toUtf8().constData(), dir);
}

void HWEngine::connect(const QString &host, quint16 port)
{
    flibConnectOfficialServer();
}

void HWEngine::sendChatMessage(const QString &msg)
{
    flibSendChatLine(msg.toUtf8().constData());
}

void HWEngine::joinRoom(const QString &roomName)
{
    flibJoinRoom(roomName.toUtf8().constData());
}

void HWEngine::partRoom(const QString &message)
{
    flibPartRoom(message.toUtf8().constData());
}

QString HWEngine::myNickname()
{
    return m_myNickname;
}

void HWEngine::setTheme(const QString &theme)
{
    flibSetTheme(theme.toUtf8().constData());
}

void HWEngine::setScript(const QString &script)
{
    flibSetScript(script.toUtf8().constData());
}

void HWEngine::setScheme(const QString &scheme)
{
    flibSetScheme(scheme.toUtf8().constData());
}

void HWEngine::setAmmo(const QString &ammo)
{
    flibSetAmmo(ammo.toUtf8().constData());
}
