#include "gameview.h"

#include <QtGui/QOpenGLContext>
#include <QtGui/QOpenGLShaderProgram>
#include <QtQuick/qquickwindow.h>

#include "flib.h"

extern "C" {
extern GameTick_t* flibGameTick;
extern ResizeWindow_t* flibResizeWindow;
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
    if (window())
        window()->update();
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

    if (m_windowChanged)
        m_renderer->setViewportSize(window()->size() * window()->devicePixelRatio());

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
