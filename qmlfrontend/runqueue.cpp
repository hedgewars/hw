#include "runqueue.h"

#include "flib.h"

extern "C" {
extern RunEngine_t* flibRunEngine;
extern ipcToEngineRaw_t* flibIpcToEngineRaw;
extern ipcSetEngineBarrier_t* flibIpcSetEngineBarrier;
extern ipcRemoveBarrierFromEngineQueue_t* flibIpcRemoveBarrierFromEngineQueue;
}

RunQueue::RunQueue(QObject* parent)
    : QObject(parent)
{
}

void RunQueue::queue(const GameConfig& config)
{
    m_runQueue.prepend(config);

    flibIpcSetEngineBarrier();
    for (const QByteArray& b : m_runQueue.last().config()) {
        flibIpcToEngineRaw(b.data(), b.size());
    }

    if (m_runQueue.size() == 1)
        nextRun();
}

void RunQueue::onGameFinished()
{
    m_runQueue.pop_front();

    nextRun();
}

void RunQueue::nextRun()
{
    if (!m_runQueue.isEmpty()) {
        if (m_runQueue[0].isPreview())
            emit previewIsRendering();

        flibIpcRemoveBarrierFromEngineQueue();

        flibRunEngine(m_runQueue[0].argc(), m_runQueue[0].argv());
    }
}
