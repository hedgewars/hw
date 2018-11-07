#include "engine_instance.h"

EngineInstance::EngineInstance(QObject *parent)
    : QObject(parent), m_instance(Engine::start_engine()) {}

EngineInstance::~EngineInstance() { Engine::cleanup(m_instance); }

Engine::PreviewInfo EngineInstance::generatePreview() {
  Engine::PreviewInfo pinfo;

  Engine::generate_preview(m_instance, &pinfo);

  return pinfo;
}
