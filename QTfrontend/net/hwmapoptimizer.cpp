#include "hwmapoptimizer.h"
#include "hwconsts.h"

HWMapOptimizer::HWMapOptimizer(QObject *parent) :
    TCPBase(parent)
{
}

bool HWMapOptimizer::couldBeRemoved()
{
    return !m_hasStarted;
}

void HWMapOptimizer::optimizeMap(const Paths &paths)
{
    m_paths = paths;

    Start(true);
}

QStringList HWMapOptimizer::getArguments()
{
    QStringList arguments;
    arguments << "--internal";
    arguments << "--port";
    arguments << QString("%1").arg(ipc_port);
    arguments << "--user-prefix";
    arguments << cfgdir->absolutePath();
    arguments << "--prefix";
    arguments << datadir->absolutePath();
    arguments << "--landpreview";
    return arguments;
}

void HWMapOptimizer::onClientDisconnect()
{

}

void HWMapOptimizer::SendToClientFirst()
{
    SendIPC("e$mapgen 4");

    /*QByteArray data = m_drawMapData;
    while(data.size() > 0)
    {
        QByteArray tmp = data;
        tmp.truncate(200);
        SendIPC("edraw " + tmp);
        data.remove(0, 200);
    }

    SendIPC("!");*/
}
