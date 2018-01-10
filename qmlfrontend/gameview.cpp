#include "gameview.h"

#include <QCursor>
#include <QTimer>
#include <QtGui/QOpenGLContext>
#include <QtGui/QOpenGLShaderProgram>
#include <QtQuick/qquickwindow.h>

#include "flib.h"

extern "C" {
extern GameTick_t* flibGameTick;
extern ResizeWindow_t* flibResizeWindow;
extern updateMousePosition_t* flibUpdateMousePosition;
}

GameView::GameView()
    : m_delta(0)
    , m_renderer(0)
    , m_windowChanged(true)
{
    connect(this, &QQuickItem::windowChanged, this, &GameView::handleWindowChanged);
}

void GameView::tick(quint32 delta)
{
    m_delta = delta;

    if (window()) {
        QTimer* timer = new QTimer(this);
        connect(timer, &QTimer::timeout, window(), &QQuickWindow::update);
        timer->start(100);

        //window()->update();
    }
}

void GameView::handleWindowChanged(QQuickWindow* win)
{
    if (win) {
        connect(win, &QQuickWindow::beforeSynchronizing, this, &GameView::sync, Qt::DirectConnection);
        connect(win, &QQuickWindow::sceneGraphInvalidated, this, &GameView::cleanup, Qt::DirectConnection);

        win->setClearBeforeRendering(false);

        m_windowChanged = true;
    }
}

void GameView::cleanup()
{
    if (m_renderer) {
        delete m_renderer;
        m_renderer = 0;
    }
}

void GameView::sync()
{
    if (!m_renderer) {
        m_renderer = new GameViewRenderer();
        connect(window(), &QQuickWindow::beforeRendering, m_renderer, &GameViewRenderer::paint, Qt::DirectConnection);
    }

    if (m_windowChanged) {
        QSize windowSize = window()->size();
        m_renderer->setViewportSize(windowSize * window()->devicePixelRatio());
        m_centerX = windowSize.width() / 2;
        m_centerY = windowSize.height() / 2;
    }

    QPoint mousePos = mapFromGlobal(QCursor::pos()).toPoint();
    if (flibUpdateMousePosition(m_centerX, m_centerY, mousePos.x(), mousePos.y()))
        QCursor::setPos(mapToGlobal(QPointF(m_centerX, m_centerY)).toPoint());

    m_renderer->tick(m_delta);
}

GameViewRenderer::~GameViewRenderer()
{
}

void GameViewRenderer::setViewportSize(const QSize& size)
{
    flibResizeWindow(size.width(), size.height());
}

void GameViewRenderer::paint()
{
    if (m_delta == 0)
        return;

    flibGameTick(m_delta);

    //m_window->resetOpenGLState();
}
