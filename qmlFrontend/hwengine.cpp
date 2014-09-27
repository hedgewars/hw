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
    getPreview_t *flibGetPreview;
    flibInit_t *flibInit;
    flibFree_t *flibFree;
}

HWEngine::HWEngine(QQmlEngine *engine, QObject *parent) :
    QObject(parent),
    m_engine(engine)
{
    QLibrary hwlib("./libhwengine.so");

    if(!hwlib.load())
        qWarning() << "Engine library not found" << hwlib.errorString();

    flibRunEngine = (RunEngine_t*) hwlib.resolve("RunEngine");
    flibRegisterGUIMessagesCallback = (registerGUIMessagesCallback_t*) hwlib.resolve("registerGUIMessagesCallback");
    flibGetPreview = (getPreview_t*) hwlib.resolve("getPreview");
    flibInit = (flibInit_t*) hwlib.resolve("flibInit");
    flibFree = (flibFree_t*) hwlib.resolve("flibFree");

    flibInit(".", "~/.hedgewars");
    flibRegisterGUIMessagesCallback(this, &guiMessagesCallback);
}

HWEngine::~HWEngine()
{
    flibFree();
}

void HWEngine::getPreview()
{
    //m_seed = QUuid::createUuid().toString();
    flibGetPreview();
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

    QMetaObject::invokeMethod(obj, "engineMessageHandler", Qt::QueuedConnection, Q_ARG(QByteArray, b));
}

void HWEngine::engineMessageHandler(const QByteArray &msg)
{
    if(msg.size() == 128 * 256)
    {
        PreviewImageProvider * preview = (PreviewImageProvider *)m_engine->imageProvider(QLatin1String("preview"));
        preview->setPixmap(msg);
        emit previewImageChanged();
    }
}

QString HWEngine::currentSeed()
{
    return m_seed;
}
