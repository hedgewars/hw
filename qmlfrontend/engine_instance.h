#ifndef ENGINEINSTANCE_H
#define ENGINEINSTANCE_H

#include <QImage>
#include <QObject>
#include <QOpenGLContext>

#include "engine_interface.h"
#include "game_config.h"

class EngineInstance : public QObject {
  Q_OBJECT

 public:
  using SimpleEventType = Engine::SimpleEventType;
  Q_ENUMS(SimpleEventType)
  using LongEventType = Engine::LongEventType;
  Q_ENUMS(LongEventType)
  using LongEventState = Engine::LongEventState;
  Q_ENUMS(LongEventState)
  using PositionedEventType = Engine::PositionedEventType;
  Q_ENUMS(PositionedEventType)

  explicit EngineInstance(const QString& libraryPath,
                          QObject* parent = nullptr);
  ~EngineInstance();

  Q_PROPERTY(bool isValid READ isValid NOTIFY isValidChanged)

  void sendConfig(const GameConfig& config);
  void renderFrame();
  void setOpenGLContext(QOpenGLContext* context);
  QImage generatePreview();

  bool isValid() const;

 signals:
  void isValidChanged(bool isValid);

 public slots:
  void advance(quint32 ticks);
  void moveCamera(const QPoint& delta);
  void simpleEvent(SimpleEventType event_type);
  void longEvent(LongEventType event_type, LongEventState state);
  void positionedEvent(PositionedEventType event_type, qint32 x, qint32 y);

 private:
  Engine::EngineInstance* m_instance;

  Engine::hedgewars_engine_protocol_version_t*
      hedgewars_engine_protocol_version;
  Engine::start_engine_t* start_engine;
  Engine::generate_preview_t* generate_preview;
  Engine::dispose_preview_t* dispose_preview;
  Engine::cleanup_t* cleanup;
  Engine::send_ipc_t* send_ipc;
  Engine::read_ipc_t* read_ipc;
  Engine::setup_current_gl_context_t* setup_current_gl_context;
  Engine::render_frame_t* render_frame;
  Engine::advance_simulation_t* advance_simulation;
  Engine::move_camera_t* move_camera;
  Engine::simple_event_t* simple_event;
  Engine::long_event_t* long_event;
  Engine::positioned_event_t* positioned_event;
  bool m_isValid;
};

Q_DECLARE_METATYPE(EngineInstance::SimpleEventType)
Q_DECLARE_METATYPE(EngineInstance::LongEventType)
Q_DECLARE_METATYPE(EngineInstance::LongEventState)
Q_DECLARE_METATYPE(EngineInstance::PositionedEventType)

#endif  // ENGINEINSTANCE_H
