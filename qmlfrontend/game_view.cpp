#include "game_view.h"

#include <QtQuick/qquickwindow.h>
#include <QCursor>
#include <QTimer>
#include <QtGui/QOpenGLContext>
#include <QtGui/QOpenGLShaderProgram>

GameView::GameView() : m_delta(0), m_windowChanged(true) {
  connect(this, &QQuickItem::windowChanged, this,
          &GameView::handleWindowChanged);
}

void GameView::tick(quint32 delta) {
  m_delta = delta;

  if (window()) {
    QTimer* timer = new QTimer(this);
    connect(timer, &QTimer::timeout, window(), &QQuickWindow::update);
    timer->start(100);

    // window()->update();
  }
}

EngineInstance* GameView::engineInstance() const { return m_engineInstance; }

void GameView::handleWindowChanged(QQuickWindow* win) {
  if (win) {
    connect(win, &QQuickWindow::beforeSynchronizing, this, &GameView::sync,
            Qt::DirectConnection);
    connect(win, &QQuickWindow::sceneGraphInvalidated, this, &GameView::cleanup,
            Qt::DirectConnection);

    win->setClearBeforeRendering(false);

    m_windowChanged = true;
  }
}

void GameView::cleanup() { m_renderer.reset(); }

void GameView::setEngineInstance(EngineInstance* engineInstance) {
  if (m_engineInstance == engineInstance) return;

  cleanup();
  m_engineInstance = engineInstance;

  emit engineInstanceChanged(m_engineInstance);
}

void GameView::sync() {
  if (!m_renderer && m_engineInstance) {
    m_engineInstance->setOpenGLContext(window()->openglContext());
    m_renderer.reset(new GameViewRenderer());
    m_renderer->setEngineInstance(m_engineInstance);
    connect(window(), &QQuickWindow::beforeRendering, m_renderer.data(),
            &GameViewRenderer::paint, Qt::DirectConnection);
  }

  if (m_windowChanged) {
    QSize windowSize = window()->size();
    m_renderer->setViewportSize(windowSize * window()->devicePixelRatio());
    m_centerX = windowSize.width() / 2;
    m_centerY = windowSize.height() / 2;
  }

  // QPoint mousePos = mapFromGlobal(QCursor::pos()).toPoint();
  // if (flibUpdateMousePosition(m_centerX, m_centerY, mousePos.x(),
  // mousePos.y()))
  //  QCursor::setPos(mapToGlobal(QPointF(m_centerX, m_centerY)).toPoint());

  if (m_renderer) m_renderer->tick(m_delta);
}

GameViewRenderer::GameViewRenderer()
    : QObject(), m_delta(0), m_engineInstance(nullptr) {}

GameViewRenderer::~GameViewRenderer() {}

void GameViewRenderer::tick(quint32 delta) { m_delta = delta; }

void GameViewRenderer::setViewportSize(const QSize& size) {
  // flibResizeWindow(size.width(), size.height());
}

void GameViewRenderer::setEngineInstance(EngineInstance* engineInstance) {
  m_engineInstance = engineInstance;
}

void GameViewRenderer::paint() {
  if (m_delta == 0) return;

  if (m_engineInstance) {
    m_engineInstance->advance(m_delta);
    m_engineInstance->renderFrame();
  }

  // m_window->resetOpenGLState();
}
