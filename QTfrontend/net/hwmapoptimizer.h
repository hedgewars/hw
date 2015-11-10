#ifndef HWMAPOPTIMIZER_H
#define HWMAPOPTIMIZER_H

#include "tcpBase.h"
#include "drawmapscene.h"

class HWMapOptimizer : public TCPBase
{
    Q_OBJECT
public:
    explicit HWMapOptimizer(QObject *parent = 0);

    void optimizeMap(const Paths & paths);
    bool couldBeRemoved();
    
signals:    
    void optimizedMap(const Paths & paths);
    
public slots:

protected:
    QStringList getArguments();
    void onClientDisconnect();
    void SendToClientFirst();

private:
    Paths m_paths;
};

#endif // HWMAPOPTIMIZER_H
