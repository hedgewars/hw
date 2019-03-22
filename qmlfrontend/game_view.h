#ifndef GAMEVIEW_H
#define GAMEVIEW_H

#include <QQuickItem>

#include <QPointer>
#include <QScopedPointer>
#include <QtGui/QOpenGLFunctions>
#include <QtGui/QOpenGLShaderProgram>

#include "engine_instance.h"

class GameViewRenderer : public QObject, protected QOpenGLFunctions {
  Q_OBJECT
 public:
  explicit GameViewRenderer();
  ~GameViewRenderer() override;

  void tick(quint32 delta);
  void setEngineInstance(EngineInstance* engineInstance);

 public slots:
  void paint();
  void onViewportSizeChanged(QQuickWindow* window);

 private:
  quint32 m_delta;
  QPointer<EngineInstance> m_engineInstance;
};

class GameView : public QQuickItem {
  Q_OBJECT

  Q_PROPERTY(EngineInstance* engineInstance READ engineInstance WRITE
                 setEngineInstance NOTIFY engineInstanceChanged)

 public:
  explicit GameView();

  Q_INVOKABLE void tick(quint32 delta);

  EngineInstance* engineInstance() const;

 signals:
  void engineInstanceChanged(EngineInstance* engineInstance);

 public slots:
  void sync();
  void cleanup();
  void setEngineInstance(EngineInstance* engineInstance);

 private slots:
  void handleWindowChanged(QQuickWindow* win);

 private:
  quint32 m_delta;
  QScopedPointer<GameViewRenderer> m_renderer;
  bool m_windowChanged;
  QPointer<EngineInstance> m_engineInstance;
  QSize m_viewportSize;
  QPoint m_centerPoint;
};

#endif  // GAMEVIEW_H
