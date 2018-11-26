#include "engine_instance.h"

#include <QDebug>
#include <QOpenGLFunctions>
#include <QSurface>

static QOpenGLContext* currentOpenglContext = nullptr;
extern "C" void (*getProcAddress(const char* fn))() {
  if (!currentOpenglContext)
    return nullptr;
  else
    return currentOpenglContext->getProcAddress(fn);
}

EngineInstance::EngineInstance(QObject* parent)
    : QObject(parent), m_instance(Engine::start_engine()) {}

EngineInstance::~EngineInstance() { Engine::cleanup(m_instance); }

void EngineInstance::sendConfig(const GameConfig& config) {
  for (auto b : config.config()) {
    Engine::send_ipc(m_instance, reinterpret_cast<uint8_t*>(b.data()),
                     static_cast<size_t>(b.size()));
  }
}

void EngineInstance::advance(quint32 ticks) {
  Engine::advance_simulation(m_instance, ticks);
}

void EngineInstance::renderFrame() { Engine::render_frame(m_instance); }

void EngineInstance::setOpenGLContext(QOpenGLContext* context) {
  currentOpenglContext = context;

  auto size = context->surface()->size();
  Engine::setup_current_gl_context(
      m_instance, static_cast<quint16>(size.width()),
      static_cast<quint16>(size.height()), &getProcAddress);
}

Engine::PreviewInfo EngineInstance::generatePreview() {
  Engine::PreviewInfo pinfo;

  Engine::generate_preview(m_instance, &pinfo);

  return pinfo;
}
