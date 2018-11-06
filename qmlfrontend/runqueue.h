#ifndef RUNQUEUE_H
#define RUNQUEUE_H

#include <QObject>

#include "gameconfig.h"

class RunQueue : public QObject {
    Q_OBJECT
public:
    explicit RunQueue(QObject* parent = nullptr);

    void queue(const GameConfig& config);

signals:
    void previewIsRendering();

public slots:
    void onGameFinished();

private:
    QList<GameConfig> m_runQueue;

    void nextRun();
};

#endif // RUNQUEUE_H
