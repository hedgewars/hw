#include "engine_instance.h"

EngineInstance::EngineInstance(QObject *parent)
    : QObject(parent), m_instance(Engine::start_engine()) {}

EngineInstance::~EngineInstance() { Engine::cleanup(m_instance); }

void EngineInstance::sendConfig(const GameConfig &config) {
  for (auto b : config.config()) {
    Engine::send_ipc(m_instance, reinterpret_cast<uint8_t *>(b.data()),
                     static_cast<size_t>(b.size()));
  }
}

Engine::PreviewInfo EngineInstance::generatePreview() {
  Engine::PreviewInfo pinfo;

  Engine::generate_preview(m_instance, &pinfo);

  return pinfo;
}
