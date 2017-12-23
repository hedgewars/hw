#ifndef HWENGINE_H
#define HWENGINE_H

#include <QList>
#include <QObject>

#include "flib.h"
#include "gameconfig.h"

class QQmlEngine;

class HWEnginePrivate;

class HWEngine : public QObject {
    Q_OBJECT

public:
    explicit HWEngine(QQmlEngine* engine, QObject* parent = nullptr);
    ~HWEngine();

    static void exposeToQML();

    Q_INVOKABLE void getPreview();
    Q_INVOKABLE void runQuickGame();

signals:
    void previewIsRendering();
    void previewImageChanged();
    void previewHogCountChanged(int count);

public slots:

private:
    QQmlEngine* m_engine;
    QList<GameConfig> m_runQueue;

    static void guiMessagesCallback(void* context, MessageType mt, const char* msg, uint32_t len);

private slots:
    void engineMessageHandler(MessageType mt, const QByteArray& msg);
};

#endif // HWENGINE_H
