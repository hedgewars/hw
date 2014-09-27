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
    Q_INVOKABLE void getPreview();
    Q_INVOKABLE QString currentSeed();
    
signals:
    void previewImageChanged();
    
public slots:

private:
    QQmlEngine * m_engine;
    QString m_seed;

    static void guiMessagesCallback(void * context, MessageType mt, const char * msg, uint32_t len);

private slots:
    void engineMessageHandler(const QByteArray &msg);
};

#endif // HWENGINE_H

