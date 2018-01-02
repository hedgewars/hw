#include "gameview.h"

#include <QtGui/QOpenGLContext>
#include <QtGui/QOpenGLShaderProgram>
#include <QtQuick/qquickwindow.h>

#include "flib.h"

extern "C" {
extern GameTick_t* flibGameTick;
}

GameView::GameView()
    : m_delta(0)
    , m_renderer(0)
{
    connect(this, &QQuickItem::windowChanged, this, &GameView::handleWindowChanged);
}

void GameView::tick(quint32 delta)
{
    m_delta = delta;
    if (window())
        window()->update();
}

void GameView::handleWindowChanged(QQuickWindow* win)
{
    if (win) {
        connect(win, &QQuickWindow::beforeSynchronizing, this, &GameView::sync, Qt::DirectConnection);
        connect(win, &QQuickWindow::sceneGraphInvalidated, this, &GameView::cleanup, Qt::DirectConnection);

        win->setClearBeforeRendering(false);
    }
}

void GameView::cleanup()
{
    if (m_renderer) {
        delete m_renderer;
        m_renderer = 0;
    }
}

GameViewRenderer::~GameViewRenderer()
{
}

void GameView::sync()
{
    if (!m_renderer) {
        m_renderer = new GameViewRenderer();
        connect(window(), &QQuickWindow::beforeRendering, m_renderer, &GameViewRenderer::paint, Qt::DirectConnection);
    }
    m_renderer->setViewportSize(window()->size() * window()->devicePixelRatio());
    m_renderer->tick(m_delta);
    m_renderer->setWindow(window());
}

void GameViewRenderer::paint()
{
    if (m_delta == 0)
        return;

    flibGameTick(m_delta);

    m_window->resetOpenGLState();
}
