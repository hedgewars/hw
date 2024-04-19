#ifndef GAMEVIEW_H
#define GAMEVIEW_H

#include <QPointer>
#include <QQuickFramebufferObject>
#include <QScopedPointer>

#include "engine_instance.h"

class GameView : public QQuickFramebufferObject {
  Q_OBJECT

  Q_PROPERTY(EngineInstance* engineInstance READ engineInstance WRITE
                 setEngineInstance NOTIFY engineInstanceChanged)

 public:
  explicit GameView(QQuickItem* parent = nullptr);

  Q_INVOKABLE void tick(quint32 delta);

  EngineInstance* engineInstance() const;

  Renderer* createRenderer() const override;

 Q_SIGNALS:
  void engineInstanceChanged(EngineInstance* engineInstance);

 public Q_SLOTS:
  void setEngineInstance(EngineInstance* engineInstance);

 private:
  quint32 m_delta;
  QPointer<EngineInstance> m_engineInstance;
  QSize m_viewportSize;
  QPoint m_centerPoint;
};

#endif  // GAMEVIEW_H
