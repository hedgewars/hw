#include "hwengine.h"

#include <QDebug>
#include <QLibrary>
#include <QQmlEngine>

extern "C" {
RunEngine_t* flibRunEngine;
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
    flibIpcToEngineRaw = (ipcToEngineRaw_t*)hwlib.resolve("ipcToEngineRaw");
    flibIpcSetEngineBarrier = (ipcSetEngineBarrier_t*)hwlib.resolve("ipcSetEngineBarrier");
    flibIpcRemoveBarrierFromEngineQueue = (ipcRemoveBarrierFromEngineQueue_t*)hwlib.resolve("ipcRemoveBarrierFromEngineQueue");
    flibRegisterUIMessagesCallback = (registerUIMessagesCallback_t*)hwlib.resolve("registerUIMessagesCallback");
    flibInit = (flibInit_t*)hwlib.resolve("flibInit");
    flibFree = (flibFree_t*)hwlib.resolve("flibFree");

    flibInit("/usr/home/unC0Rr/Sources/Hedgewars/MainRepo/share/hedgewars/Data", "/usr/home/unC0Rr/.hedgewars");
    flibRegisterUIMessagesCallback(this, &guiMessagesCallback);
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
    case MSG_RENDERINGPREVIEW: {
        qDebug("MSG_RENDERINGPREVIEW");
        emit previewIsRendering();
        break;
    }
    case MSG_PREVIEW: {
        qDebug("MSG_PREVIEW");
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
        break;
    }
    }
}

void HWEngine::getPreview()
{
    GameConfig cfg;
    cfg.cmdSeed("superseed");
    m_runQueue.append(cfg);
    flibIpcSetEngineBarrier();
    for (const QByteArray& b : m_runQueue[0].config()) {
        qDebug() << "[frontend] sending msg of size" << b.size();
        flibIpcToEngineRaw(b.data(), b.size());
    }
    flibIpcRemoveBarrierFromEngineQueue();
    flibRunEngine(m_runQueue[0].argc(), m_runQueue[0].argv());
}

void HWEngine::runQuickGame()
{
}
