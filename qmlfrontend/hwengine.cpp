#include <QDebug>
#include <QLibrary>
#include <QQmlEngine>
#include <QUuid>

#include "engine_instance.h"
#include "engine_interface.h"
#include "game_view.h"
#include "preview_image_provider.h"

#include "hwengine.h"

HWEngine::HWEngine(QQmlEngine* engine, QObject* parent)
    : QObject(parent),
      m_engine(engine),
      m_previewProvider(new PreviewImageProvider()) {
  m_engine->addImageProvider(QLatin1String("preview"), m_previewProvider);
}

HWEngine::~HWEngine() {}

static QObject* hwengine_singletontype_provider(QQmlEngine* engine,
                                                QJSEngine* scriptEngine) {
  Q_UNUSED(scriptEngine)

  HWEngine* hwengine = new HWEngine(engine);
  return hwengine;
}

void HWEngine::exposeToQML() {
  qDebug("HWEngine::exposeToQML");
  qmlRegisterSingletonType<HWEngine>("Hedgewars.Engine", 1, 0, "HWEngine",
                                     hwengine_singletontype_provider);
  // qmlRegisterType<GameView>("Hedgewars.Engine", 1, 0, "GameView");
}

void HWEngine::getPreview() {
  m_seed = QUuid::createUuid().toByteArray();
  m_gameConfig.cmdSeed(m_seed);
  m_gameConfig.setPreview(true);

  EngineInstance engine;
  Engine::PreviewInfo preview = engine.generatePreview();

  QVector<QRgb> colorTable;
  colorTable.resize(256);
  for (int i = 0; i < 256; ++i) colorTable[i] = qRgba(255, 255, 0, i);

  QImage previewImage(preview.land, preview.width, preview.height,
                      QImage::Format_Indexed8);
  previewImage.setColorTable(colorTable);
  previewImage.detach();

  m_previewProvider->setImage(previewImage);

  emit previewImageChanged();
  // m_runQueue->queue(m_gameConfig);
}

void HWEngine::runQuickGame() {
  m_gameConfig.cmdSeed(m_seed);
  m_gameConfig.cmdTheme("Nature");
  Team team1;
  team1.name = "team1";
  Team team2;
  team2.name = "team2";
  team2.color = "7654321";
  m_gameConfig.cmdTeam(team1);
  m_gameConfig.cmdTeam(team2);
  m_gameConfig.setPreview(false);

  // m_runQueue->queue(m_gameConfig);
}

int HWEngine::previewHedgehogsCount() const { return m_previewHedgehogsCount; }
