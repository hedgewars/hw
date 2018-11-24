#ifndef ENGINEINSTANCE_H
#define ENGINEINSTANCE_H

#include "engine_interface.h"

#include <QObject>
#include <QOpenGLContext>

#include "game_config.h"

class EngineInstance : public QObject {
  Q_OBJECT
 public:
  explicit EngineInstance(QObject* parent = nullptr);
  ~EngineInstance();

  void sendConfig(const GameConfig& config);
  void advance(quint32 ticks);
  void renderFrame();
  void setOpenGLContext(QOpenGLContext* context);
  Engine::PreviewInfo generatePreview();

 signals:

 public slots:

 private:
  Engine::EngineInstance* m_instance;
};

#endif  // ENGINEINSTANCE_H
