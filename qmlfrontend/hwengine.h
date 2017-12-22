#ifndef HWENGINE_H
#define HWENGINE_H

#include <QObject>

#include "flib.h"

class QQmlEngine;

class HWEnginePrivate;

class HWEngine : public QObject {
    Q_OBJECT

public:
    explicit HWEngine(QQmlEngine* engine, QObject* parent = nullptr);
    ~HWEngine();

    static void exposeToQML();

signals:
    void previewIsRendering();
    void previewImageChanged();
    void previewHogCountChanged(int count);

public slots:

private:
    QQmlEngine* m_engine;

    static void guiMessagesCallback(void* context, MessageType mt, const char* msg, uint32_t len);

private slots:
    void engineMessageHandler(MessageType mt, const QByteArray& msg);
};

#endif // HWENGINE_H
