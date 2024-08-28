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
  void executeActions();

 Q_SIGNALS:
  void engineInstanceChanged(EngineInstance* engineInstance);

 public Q_SLOTS:
  void setEngineInstance(EngineInstance* engineInstance);

 private:
  QPointer<EngineInstance> m_engineInstance;
  QSize m_viewportSize;
  QPoint m_centerPoint;
  QList<std::function<void(EngineInstance*)>> m_actions;

  void addAction(std::function<void(EngineInstance*)>&& action);
};

#endif  // GAMEVIEW_H
