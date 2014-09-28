#include <QLibrary>
#include <QtQml>
#include <QDebug>
#include <QPainter>
#include <QUuid>

#include "hwengine.h"
#include "previewimageprovider.h"

extern "C" {
    RunEngine_t *flibRunEngine;
    registerGUIMessagesCallback_t *flibRegisterGUIMessagesCallback;
    setSeed_t *flibSetSeed;
    getSeed_t *flibGetSeed;
    getPreview_t *flibGetPreview;
    runQuickGame_t *flibRunQuickGame;
    flibInit_t *flibInit;
    flibFree_t *flibFree;
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
    flibInit = (flibInit_t*) hwlib.resolve("flibInit");
    flibFree = (flibFree_t*) hwlib.resolve("flibFree");

    flibInit("/usr/home/unC0Rr/Sources/Hedgewars/Hedgewars-GC/share/hedgewars/Data", "~/.hedgewars");
    flibRegisterGUIMessagesCallback(this, &guiMessagesCallback);
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
    QByteArray b = QByteArray::fromRawData(msg, len);

    qDebug() << "FLIPC in" << b.size() << b;

    QMetaObject::invokeMethod(obj, "engineMessageHandler", Qt::QueuedConnection, Q_ARG(MessageType, mt), Q_ARG(QByteArray, b));
}

void HWEngine::engineMessageHandler(MessageType mt, const QByteArray &msg)
{
    switch(mt)
    {
    case MSG_PREVIEW:
        PreviewImageProvider * preview = (PreviewImageProvider *)m_engine->imageProvider(QLatin1String("preview"));
        preview->setPixmap(msg);
        emit previewImageChanged();
        break;
    }
}

QString HWEngine::currentSeed()
{
    return QString::fromLatin1(flibGetSeed());
}
