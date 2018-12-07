#include "hwengine.h"

#include <QDebug>
#include <QImage>
#include <QLibrary>
#include <QQmlEngine>
#include <QUuid>

#include "engine_instance.h"
#include "engine_interface.h"
#include "game_view.h"
#include "preview_acceptor.h"

HWEngine::HWEngine(QObject* parent) : QObject(parent) {}

HWEngine::~HWEngine() {}

void HWEngine::getPreview() {
  emit previewIsRendering();

  m_gameConfig = GameConfig();
  m_gameConfig.cmdSeed(QUuid::createUuid().toByteArray());

  EngineInstance engine(m_engineLibrary);
  if (!engine.isValid())  // TODO: error notification
    return;

  engine.sendConfig(m_gameConfig);

  Engine::PreviewInfo preview = engine.generatePreview();

  QVector<QRgb> colorTable;
  colorTable.resize(256);
  for (int i = 0; i < 256; ++i) colorTable[i] = qRgba(255, 255, 0, i);

  QImage previewImage(preview.land, static_cast<int>(preview.width),
                      static_cast<int>(preview.height),
                      QImage::Format_Indexed8);
  previewImage.setColorTable(colorTable);
  previewImage.detach();

  if (m_previewAcceptor) m_previewAcceptor->setImage(previewImage);

  emit previewImageChanged();
  // m_runQueue->queue(m_gameConfig);
}

EngineInstance* HWEngine::runQuickGame() {
  m_gameConfig.cmdTheme("Nature");
  Team team1;
  team1.name = "team1";
  Team team2;
  team2.name = "team2";
  team2.color = "7654321";
  m_gameConfig.cmdTeam(team1);
  m_gameConfig.cmdTeam(team2);

  EngineInstance* engine = new EngineInstance(m_engineLibrary, this);

  return engine;
  // m_runQueue->queue(m_gameConfig);
}

int HWEngine::previewHedgehogsCount() const { return m_previewHedgehogsCount; }

PreviewAcceptor* HWEngine::previewAcceptor() const { return m_previewAcceptor; }

QString HWEngine::engineLibrary() const { return m_engineLibrary; }

void HWEngine::setPreviewAcceptor(PreviewAcceptor* previewAcceptor) {
  if (m_previewAcceptor == previewAcceptor) return;

  m_previewAcceptor = previewAcceptor;
  emit previewAcceptorChanged(m_previewAcceptor);
}

void HWEngine::setEngineLibrary(const QString& engineLibrary) {
  if (m_engineLibrary == engineLibrary) return;

  m_engineLibrary = engineLibrary;
  emit engineLibraryChanged(m_engineLibrary);
}
