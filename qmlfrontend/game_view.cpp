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
  bool m_dirty{true};
  QSizeF m_gameViewSize;
};

void GameViewRenderer::render() {
  const auto engine = m_gameView->engineInstance();

  if (!engine) {
    return;
  }

  if (m_dirty) {
    m_dirty = false;
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

  if (const auto currentSize = m_gameView->size();
      currentSize != m_gameViewSize) {
    m_gameViewSize = currentSize;
    m_dirty = true;
  }

  m_gameView->executeActions();
}

GameView::GameView(QQuickItem* parent) : QQuickFramebufferObject(parent) {
  setMirrorVertically(true);
}

void GameView::tick(quint32 delta) {
  addAction([delta](auto engine) { engine->advance(delta); });
}

EngineInstance* GameView::engineInstance() const { return m_engineInstance; }

QQuickFramebufferObject::Renderer* GameView::createRenderer() const {
  return new GameViewRenderer{};
}

void GameView::executeActions() {
  if (!m_engineInstance) {
    return;
  }

  for (const auto& action : m_actions) {
    action(m_engineInstance);
  }

  m_actions.clear();
}

void GameView::setEngineInstance(EngineInstance* engineInstance) {
  if (m_engineInstance == engineInstance) {
    return;
  }

  m_engineInstance = engineInstance;

  Q_EMIT engineInstanceChanged(m_engineInstance);
}

void GameView::addAction(std::function<void(EngineInstance*)>&& action) {
  m_actions.append(std::move(action));
}
