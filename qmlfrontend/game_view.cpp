#include "game_view.h"

#include <QtQuick/qquickwindow.h>

#include <QCursor>
#include <QOpenGLFramebufferObjectFormat>
#include <QQuickOpenGLUtils>
#include <QTimer>
#include <QtGui/QOpenGLContext>

class GameViewRenderer : public QQuickFramebufferObject::Renderer {
 public:
  explicit GameViewRenderer() = default;

  GameViewRenderer(const GameViewRenderer&) = delete;
  GameViewRenderer(GameViewRenderer&&) = delete;
  GameViewRenderer& operator=(const GameViewRenderer&) = delete;
  GameViewRenderer& operator=(GameViewRenderer&&) = delete;

  void render() override;
  QOpenGLFramebufferObject* createFramebufferObject(const QSize& size) override;
  void synchronize(QQuickFramebufferObject* fbo) override;

  QPointer<GameView> m_gameView;
  QPointer<QQuickWindow> m_window;
  bool m_inited{false};
};

void GameViewRenderer::render() {
  const auto engine = m_gameView->engineInstance();

  if (!engine) {
    return;
  }

  if (!m_inited) {
    m_inited = true;
    engine->setOpenGLContext(QOpenGLContext::currentContext());
  }

  engine->renderFrame();

  QQuickOpenGLUtils::resetOpenGLState();
}

QOpenGLFramebufferObject* GameViewRenderer::createFramebufferObject(
    const QSize& size) {
  QOpenGLFramebufferObjectFormat format;
  format.setAttachment(QOpenGLFramebufferObject::CombinedDepthStencil);
  format.setSamples(8);
  auto fbo = new QOpenGLFramebufferObject(size, format);
  return fbo;
}

void GameViewRenderer::synchronize(QQuickFramebufferObject* fbo) {
  if (!m_gameView) {
    m_gameView = qobject_cast<GameView*>(fbo);
    m_window = fbo->window();
  }
}

GameView::GameView(QQuickItem* parent)
    : QQuickFramebufferObject(parent), m_delta(0) {
  setMirrorVertically(true);
}

void GameView::tick(quint32 delta) {
  m_delta = delta;

  if (window()) {
    QTimer* timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, &GameView::update);
    timer->start(100);
  }
}

EngineInstance* GameView::engineInstance() const { return m_engineInstance; }

QQuickFramebufferObject::Renderer* GameView::createRenderer() const {
  return new GameViewRenderer{};
}

void GameView::setEngineInstance(EngineInstance* engineInstance) {
  if (m_engineInstance == engineInstance) {
    return;
  }

  m_engineInstance = engineInstance;

  Q_EMIT engineInstanceChanged(m_engineInstance);
}
