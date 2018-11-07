#ifndef ENGINEINSTANCE_H
#define ENGINEINSTANCE_H

#include "engine_interface.h"

#include <QObject>

class EngineInstance : public QObject {
  Q_OBJECT
 public:
  explicit EngineInstance(QObject *parent = nullptr);
  ~EngineInstance();

  Engine::PreviewInfo generatePreview();

 signals:

 public slots:

 private:
  Engine::EngineInstance *m_instance;
};

#endif  // ENGINEINSTANCE_H
