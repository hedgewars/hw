#include <QLibrary>
#include <QtQml>
#include <QDebug>

#include "hwengine.h"

extern "C" {
    void (*RunEngine)(int argc, char ** argv);
}

HWEngine::HWEngine(QObject *parent) :
    QObject(parent)
{
    QLibrary hwlib("./libhwengine.so");

    if(!hwlib.load())
        qWarning() << "Engine library not found" << hwlib.errorString();

    RunEngine = (void (*)(int, char **))hwlib.resolve("RunEngine");
}

HWEngine::~HWEngine()
{

}

void HWEngine::run()
{
    char* args[2] = {"", "--help"};
    RunEngine(2, args);
}

static QObject *hwengine_singletontype_provider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    HWEngine *hwengine = new HWEngine();
    return hwengine;
}

void HWEngine::exposeToQML()
{
    qDebug("HWEngine::exposeToQML");
    qmlRegisterSingletonType<HWEngine>("Hedgewars.Engine", 1, 0, "HWEngine", hwengine_singletontype_provider);
}
