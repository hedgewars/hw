#ifndef HWENGINE_H
#define HWENGINE_H

#include <QObject>
#include <QByteArray>
#include <QVector>
#include <QPixmap>

#include "flib.h"

class QQmlEngine;

class HWEngine : public QObject
{
    Q_OBJECT
public:
    explicit HWEngine(QQmlEngine * engine, QObject *parent = 0);
    ~HWEngine();

    static void exposeToQML();
    Q_INVOKABLE void run();
    Q_INVOKABLE QString currentSeed();
    
signals:
    void previewImageChanged();
    
public slots:

private:
    QList<QByteArray> m_argsList;
    QVector<const char *> m_args;
    QQmlEngine * m_engine;
    QString m_seed;

    static void engineMessageCallback(void *context, const char * msg, quint32 len);
    void sendIPC(const QByteArray &b);

private slots:
    void engineMessageHandler(const QByteArray &msg);
};

#endif // HWENGINE_H

