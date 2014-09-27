#include <QLibrary>
#include <QtQml>
#include <QDebug>
#include <QPainter>
#include <QUuid>

#include "hwengine.h"
#include "previewimageprovider.h"

extern "C" {
    RunEngine_t *RunEngine;
    registerPreviewCallback_t *registerPreviewCallback;
    ipcToEngine_t *ipcToEngine;
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

    RunEngine = (RunEngine_t*) hwlib.resolve("RunEngine");
    registerPreviewCallback = (registerPreviewCallback_t*) hwlib.resolve("registerIPCCallback");
    ipcToEngine = (ipcToEngine_t*) hwlib.resolve("ipcToEngine");
    flibInit = (flibInit_t*) hwlib.resolve("flibInit");
    flibFree = (flibFree_t*) hwlib.resolve("flibFree");

    flibInit(".", "~/.hedgewars");
    registerPreviewCallback(this, &enginePreviewCallback);
}

HWEngine::~HWEngine()
{
    flibFree();
}

void HWEngine::run()
{
    m_argsList.clear();
    m_argsList << "";
    m_argsList << "--internal";
    m_argsList << "--landpreview";

    m_args.resize(m_argsList.size());
    for(int i = m_argsList.size() - 1; i >=0; --i)
        m_args[i] = m_argsList[i].constData();

    m_seed = QUuid::createUuid().toString();

    RunEngine(m_args.size(), m_args.data());
    sendIPC("eseed " + m_seed.toLatin1());
    sendIPC("e$mapgen 0");
    sendIPC("!");
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

void HWEngine::sendIPC(const QByteArray & b)
{
    quint8 len = b.size() > 255 ? 255 : b.size();
    qDebug() << "sendIPC: len = " << len;

    ipcToEngine(b.constData(), len);
}

void HWEngine::enginePreviewCallback(void *context, const char * msg, quint32 len)
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
