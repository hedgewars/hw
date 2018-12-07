#include "engine_instance.h"

#include <QDebug>
#include <QLibrary>
#include <QOpenGLFunctions>
#include <QSurface>

static QOpenGLContext* currentOpenglContext = nullptr;
extern "C" void (*getProcAddress(const char* fn))() {
  if (!currentOpenglContext)
    return nullptr;
  else
    return currentOpenglContext->getProcAddress(fn);
}

EngineInstance::EngineInstance(const QString& libraryPath, QObject* parent)
    : QObject(parent) {
  QLibrary hwlib(libraryPath);

  if (!hwlib.load())
    qWarning() << "Engine library not found" << hwlib.errorString();

  hedgewars_engine_protocol_version =
      reinterpret_cast<Engine::hedgewars_engine_protocol_version_t*>(
          hwlib.resolve("hedgewars_engine_protocol_version"));
  start_engine =
      reinterpret_cast<Engine::start_engine_t*>(hwlib.resolve("start_engine"));
  generate_preview = reinterpret_cast<Engine::generate_preview_t*>(
      hwlib.resolve("generate_preview"));
  cleanup = reinterpret_cast<Engine::cleanup_t*>(hwlib.resolve("cleanup"));

  send_ipc = reinterpret_cast<Engine::send_ipc_t*>(hwlib.resolve("send_ipc"));
  read_ipc = reinterpret_cast<Engine::read_ipc_t*>(hwlib.resolve("read_ipc"));

  setup_current_gl_context =
      reinterpret_cast<Engine::setup_current_gl_context_t*>(
          hwlib.resolve("setup_current_gl_context"));
  render_frame =
      reinterpret_cast<Engine::render_frame_t*>(hwlib.resolve("render_frame"));
  advance_simulation = reinterpret_cast<Engine::advance_simulation_t*>(
      hwlib.resolve("advance_simulation"));

  m_isValid = hedgewars_engine_protocol_version && start_engine &&
              generate_preview && cleanup && send_ipc && read_ipc &&
              setup_current_gl_context && render_frame && advance_simulation;
  emit isValidChanged(m_isValid);

  if (isValid()) {
    qDebug() << "Loaded engine library with protocol version"
             << hedgewars_engine_protocol_version();

    m_instance = start_engine();
  }
}

EngineInstance::~EngineInstance() {
  if (m_isValid) cleanup(m_instance);
}

void EngineInstance::sendConfig(const GameConfig& config) {
  for (auto b : config.config()) {
    send_ipc(m_instance, reinterpret_cast<uint8_t*>(b.data()),
             static_cast<size_t>(b.size()));
  }
}

void EngineInstance::advance(quint32 ticks) {
  advance_simulation(m_instance, ticks);
}

void EngineInstance::renderFrame() { render_frame(m_instance); }

void EngineInstance::setOpenGLContext(QOpenGLContext* context) {
  currentOpenglContext = context;

  auto size = context->surface()->size();
  setup_current_gl_context(m_instance, static_cast<quint16>(size.width()),
                           static_cast<quint16>(size.height()),
                           &getProcAddress);
}

Engine::PreviewInfo EngineInstance::generatePreview() {
  Engine::PreviewInfo pinfo;

  generate_preview(m_instance, &pinfo);

  return pinfo;
}

bool EngineInstance::isValid() const { return m_isValid; }
