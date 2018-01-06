#include "hwengine.h"

#include <QDebug>
#include <QLibrary>
#include <QQmlEngine>
#include <QUuid>

#include "gameview.h"
#include "previewimageprovider.h"
#include "runqueue.h"

extern "C" {
RunEngine_t* flibRunEngine;
GameTick_t* flibGameTick;
ipcToEngineRaw_t* flibIpcToEngineRaw;
ipcSetEngineBarrier_t* flibIpcSetEngineBarrier;
ipcRemoveBarrierFromEngineQueue_t* flibIpcRemoveBarrierFromEngineQueue;
registerUIMessagesCallback_t* flibRegisterUIMessagesCallback;
flibInit_t* flibInit;
flibFree_t* flibFree;
passFlibEvent_t* flibPassFlibEvent;
}

HWEngine::HWEngine(QQmlEngine* engine, QObject* parent)
    : QObject(parent)
    , m_engine(engine)
    , m_previewProvider(new PreviewImageProvider())
    , m_runQueue(new RunQueue(this))
{
    qRegisterMetaType<MessageType>("MessageType");

#ifdef Q_OS_WIN
    QLibrary hwlib("./libhwengine.dll");
#else
    QLibrary hwlib("./libhwengine.so");
#endif

    if (!hwlib.load())
        qWarning() << "Engine library not found" << hwlib.errorString();

    flibRunEngine = (RunEngine_t*)hwlib.resolve("RunEngine");
    flibGameTick = (GameTick_t*)hwlib.resolve("GameTick");
    flibIpcToEngineRaw = (ipcToEngineRaw_t*)hwlib.resolve("ipcToEngineRaw");
    flibIpcSetEngineBarrier = (ipcSetEngineBarrier_t*)hwlib.resolve("ipcSetEngineBarrier");
    flibIpcRemoveBarrierFromEngineQueue = (ipcRemoveBarrierFromEngineQueue_t*)hwlib.resolve("ipcRemoveBarrierFromEngineQueue");
    flibRegisterUIMessagesCallback = (registerUIMessagesCallback_t*)hwlib.resolve("registerUIMessagesCallback");
    flibInit = (flibInit_t*)hwlib.resolve("flibInit");
    flibFree = (flibFree_t*)hwlib.resolve("flibFree");

    flibInit("/usr/home/unC0Rr/Sources/Hedgewars/MainRepo/share/hedgewars/Data", "/usr/home/unC0Rr/.hedgewars");
    flibRegisterUIMessagesCallback(this, &guiMessagesCallback);

    m_engine->addImageProvider(QLatin1String("preview"), m_previewProvider);

    connect(m_runQueue, &RunQueue::previewIsRendering, this, &HWEngine::previewIsRendering);
    connect(this, &HWEngine::gameFinished, m_runQueue, &RunQueue::onGameFinished);
}

HWEngine::~HWEngine()
{
    flibFree();
}

static QObject* hwengine_singletontype_provider(QQmlEngine* engine, QJSEngine* scriptEngine)
{
    Q_UNUSED(scriptEngine)

    HWEngine* hwengine = new HWEngine(engine);
    return hwengine;
}

void HWEngine::exposeToQML()
{
    qDebug("HWEngine::exposeToQML");
    qmlRegisterSingletonType<HWEngine>("Hedgewars.Engine", 1, 0, "HWEngine", hwengine_singletontype_provider);
    qmlRegisterType<GameView>("Hedgewars.Engine", 1, 0, "GameView");
}

void HWEngine::guiMessagesCallback(void* context, MessageType mt, const char* msg, uint32_t len)
{
    HWEngine* obj = reinterpret_cast<HWEngine*>(context);
    QByteArray b = QByteArray(msg, len);

    qDebug() << "FLIPC in" << mt << " size = " << b.size();

    QMetaObject::invokeMethod(obj, "engineMessageHandler", Qt::QueuedConnection, Q_ARG(MessageType, mt), Q_ARG(QByteArray, b));
}

void HWEngine::engineMessageHandler(MessageType mt, const QByteArray& msg)
{
    switch (mt) {
    case MSG_PREVIEW: {
        qDebug("MSG_PREVIEW");
        m_previewProvider->setPixmap(msg);
        emit previewImageChanged();
        break;
    }
    case MSG_PREVIEWHOGCOUNT: {
        qDebug("MSG_PREVIEWHOGCOUNT");
        emit previewHogCountChanged((quint8)msg.data()[0]);
        break;
    }
    case MSG_TONET: {
        qDebug("MSG_TONET");
        break;
    }
    case MSG_GAMEFINISHED: {
        qDebug("MSG_GAMEFINISHED");
        emit gameFinished();
        break;
    }
    }
}

void HWEngine::getPreview()
{
    m_seed = QUuid::createUuid().toByteArray();
    m_gameConfig.cmdSeed(m_seed);
    m_gameConfig.setPreview(true);

    m_runQueue->queue(m_gameConfig);
}

void HWEngine::runQuickGame()
{
    m_gameConfig.cmdSeed(m_seed);
    m_gameConfig.cmdTheme("Nature");
    Team team1;
    team1.name = "team1";
    Team team2;
    team2.name = "team2";
    team2.color = "7654321";
    m_gameConfig.cmdTeam(team1);
    m_gameConfig.cmdTeam(team2);
    m_gameConfig.setPreview(false);

    m_runQueue->queue(m_gameConfig);
}
