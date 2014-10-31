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
    registerGUIMessagesCallback_t *flibRegisterGUIMessagesCallback;
    setSeed_t *flibSetSeed;
    getSeed_t *flibGetSeed;
    getPreview_t *flibGetPreview;
    runQuickGame_t *flibRunQuickGame;
    runLocalGame_t *flibRunLocalGame;
    flibInit_t *flibInit;
    flibFree_t *flibFree;
    getThemesList_t *flibGetThemesList;
    freeThemesList_t *flibFreeThemesList;
    getThemeIcon_t *flibGetThemeIcon;
    getTeamsList_t *flibGetTeamsList;
    tryAddTeam_t * flibTryAddTeam;
    tryRemoveTeam_t * flibTryRemoveTeam;
}

Q_DECLARE_METATYPE(MessageType);

HWEngine::HWEngine(QQmlEngine *engine, QObject *parent) :
    QObject(parent),
    m_engine(engine)
{
    qRegisterMetaType<MessageType>("MessageType");

    QLibrary hwlib("./libhwengine.so");

    if(!hwlib.load())
        qWarning() << "Engine library not found" << hwlib.errorString();

    flibRunEngine = (RunEngine_t*) hwlib.resolve("RunEngine");
    flibRegisterGUIMessagesCallback = (registerGUIMessagesCallback_t*) hwlib.resolve("registerGUIMessagesCallback");
    flibSetSeed = (setSeed_t*) hwlib.resolve("setSeed");
    flibGetSeed = (getSeed_t*) hwlib.resolve("getSeed");
    flibGetPreview = (getPreview_t*) hwlib.resolve("getPreview");
    flibRunQuickGame = (runQuickGame_t*) hwlib.resolve("runQuickGame");
    flibRunLocalGame = (runLocalGame_t*) hwlib.resolve("runLocalGame");
    flibInit = (flibInit_t*) hwlib.resolve("flibInit");
    flibFree = (flibFree_t*) hwlib.resolve("flibFree");

    flibGetThemesList = (getThemesList_t*) hwlib.resolve("getThemesList");
    flibFreeThemesList = (freeThemesList_t*) hwlib.resolve("freeThemesList");
    flibGetThemeIcon = (getThemeIcon_t*) hwlib.resolve("getThemeIcon");

    flibGetTeamsList = (getTeamsList_t*) hwlib.resolve("getTeamsList");
    flibTryAddTeam = (tryAddTeam_t*) hwlib.resolve("tryAddTeam");
    flibTryRemoveTeam = (tryRemoveTeam_t*) hwlib.resolve("tryRemoveTeam");

    flibInit("/usr/home/unC0Rr/Sources/Hedgewars/Hedgewars-GC/share/hedgewars/Data", "/usr/home/unC0Rr/.hedgewars");
    flibRegisterGUIMessagesCallback(this, &guiMessagesCallback);

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

    qDebug() << "FLIPC in" << b.size() << b;

    QMetaObject::invokeMethod(obj, "engineMessageHandler", Qt::QueuedConnection, Q_ARG(MessageType, mt), Q_ARG(QByteArray, b));
}

void HWEngine::engineMessageHandler(MessageType mt, const QByteArray &msg)
{
    switch(mt)
    {
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
        emit playingTeamRemoved(msg);
        break;
    }
    case MSG_ADDTEAM: {
        emit localTeamAdded(msg, 0);
        break;
    }
    case MSG_REMOVETEAM: {
        emit localTeamRemoved(msg);
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
    for (char **i = themes; *i != NULL; i++) {
        QString theme = QString::fromUtf8(*i);

        resultModel << theme;
    }
    flibFreeThemesList(themes);

    m_engine->rootContext()->setContextProperty("themesModel", QVariant::fromValue(resultModel));
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
