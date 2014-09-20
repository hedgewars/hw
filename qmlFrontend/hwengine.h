#ifndef HWENGINE_H
#define HWENGINE_H

#include <QObject>
#include <QByteArray>
#include <QVector>

#include "flib.h"

class HWEngine : public QObject
{
    Q_OBJECT
public:
    explicit HWEngine(QObject *parent = 0);
    ~HWEngine();

    static void exposeToQML();
    Q_INVOKABLE void run();
    
signals:
    
public slots:

private:
    QList<QByteArray> m_argsList;
    QVector<const char *> m_args;

    static void engineMessageCallback(void *context, quint8 len, const char * msg);
    void sendIPC(const QByteArray &b);
};

#endif // HWENGINE_H

