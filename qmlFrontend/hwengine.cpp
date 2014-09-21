#include <QLibrary>
#include <QtQml>
#include <QDebug>
#include <QPainter>

#include "hwengine.h"
#include "previewimageprovider.h"

extern "C" {
    RunEngine_t *RunEngine;
    registerIPCCallback_t *registerIPCCallback;
    ipcToEngine_t *ipcToEngine;
    flibInit_t *flibInit;
}

HWEngine::HWEngine(QQmlEngine *engine, QObject *parent) :
    QObject(parent),
    m_engine(engine)
{
    QLibrary hwlib("./libhwengine.so");

    if(!hwlib.load())
        qWarning() << "Engine library not found" << hwlib.errorString();

    RunEngine = (RunEngine_t*) hwlib.resolve("RunEngine");
    registerIPCCallback = (registerIPCCallback_t*) hwlib.resolve("registerIPCCallback");
    ipcToEngine = (ipcToEngine_t*) hwlib.resolve("ipcToEngine");
    flibInit = (flibInit_t*) hwlib.resolve("flibInit");

    flibInit();
    registerIPCCallback(this, &engineMessageCallback);
}

HWEngine::~HWEngine()
{

}

void HWEngine::run()
{
    m_argsList.clear();
    m_argsList << "";
    m_argsList << "--internal";
    //m_argsList << "--user-prefix";
    //m_argsList << cfgdir->absolutePath();
    //m_argsList << "--prefix";
    //m_argsList << datadir->absolutePath();
    m_argsList << "--landpreview";

    m_args.resize(m_argsList.size());
    for(int i = m_argsList.size() - 1; i >=0; --i)
        m_args[i] = m_argsList[i].constData();

    RunEngine(m_args.size(), m_args.data());
    sendIPC("eseed helloworld");
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

void HWEngine::engineMessageCallback(void *context, const char * msg, quint32 len)
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
        QVector<QRgb> colorTable;
        colorTable.resize(256);
        for(int i = 0; i < 256; ++i)
            colorTable[i] = qRgba(255, 255, 0, i);

        const quint8 *buf = (const quint8*) msg.constData();
        QImage im(buf, 256, 128, QImage::Format_Indexed8);
        im.setColorTable(colorTable);

        QPixmap px = QPixmap::fromImage(im, Qt::ColorOnly);
        //QPixmap pxres(px.size());
        //QPainter p(&pxres);

        //p.fillRect(pxres.rect(), linearGrad);
        //p.drawPixmap(0, 0, px);

        PreviewImageProvider * preview = (PreviewImageProvider *)m_engine->imageProvider(QLatin1String("preview"));
        preview->setPixmap(px);
        emit previewImageChanged();
    }
}
