#ifndef ENGINEINSTANCE_H
#define ENGINEINSTANCE_H

#include <QObject>
#include <QOpenGLContext>

#include "engine_interface.h"
#include "game_config.h"

class EngineInstance : public QObject {
  Q_OBJECT
 public:
  explicit EngineInstance(const QString& libraryPath,
                          QObject* parent = nullptr);
  ~EngineInstance();

  Q_PROPERTY(bool isValid READ isValid NOTIFY isValidChanged)

  void sendConfig(const GameConfig& config);
  void advance(quint32 ticks);
  void renderFrame();
  void setOpenGLContext(QOpenGLContext* context);
  Engine::PreviewInfo generatePreview();

  bool isValid() const;

 signals:
  void isValidChanged(bool isValid);

 public slots:

 private:
  Engine::EngineInstance* m_instance;

  Engine::hedgewars_engine_protocol_version_t*
      hedgewars_engine_protocol_version;
  Engine::start_engine_t* start_engine;
  Engine::generate_preview_t* generate_preview;
  Engine::cleanup_t* cleanup;
  Engine::send_ipc_t* send_ipc;
  Engine::read_ipc_t* read_ipc;
  Engine::setup_current_gl_context_t* setup_current_gl_context;
  Engine::render_frame_t* render_frame;
  Engine::advance_simulation_t* advance_simulation;
  bool m_isValid;
};

#endif  // ENGINEINSTANCE_H
