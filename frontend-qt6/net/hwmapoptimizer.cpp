#include "hwmapoptimizer.h"

#include "hwconsts.h"

HWMapOptimizer::HWMapOptimizer(QObject *parent)
    : TCPBase(false, false, parent) {}

bool HWMapOptimizer::couldBeRemoved() { return !m_hasStarted; }

void HWMapOptimizer::optimizeMap(const Paths &paths) {
  m_paths = paths;

  Start(true);
}

QStringList HWMapOptimizer::getArguments() {
  QStringList arguments;
  arguments << QStringLiteral("--internal");
  arguments << QStringLiteral("--port");
  arguments << QStringLiteral("%1").arg(ipc_port);
  arguments << QStringLiteral("--user-prefix");
  arguments << cfgdir.absolutePath();
  arguments << QStringLiteral("--prefix");
  arguments << datadir.absolutePath();
  arguments << QStringLiteral("--landpreview");
  return arguments;
}

void HWMapOptimizer::onClientDisconnect() {}

void HWMapOptimizer::SendToClientFirst() {
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
