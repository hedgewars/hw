#ifndef HWENGINE_H
#define HWENGINE_H

#include <QList>
#include <QObject>

#include "engine_interface.h"
#include "game_config.h"

class QQmlEngine;
class PreviewImageProvider;
class EngineInstance;

class HWEngine : public QObject {
  Q_OBJECT

  Q_PROPERTY(int previewHedgehogsCount READ previewHedgehogsCount NOTIFY
                 previewHedgehogsCountChanged)

 public:
  explicit HWEngine(QQmlEngine* engine, QObject* parent = nullptr);
  ~HWEngine();

  static void exposeToQML();

  Q_INVOKABLE void getPreview();
  Q_INVOKABLE EngineInstance* runQuickGame();

  int previewHedgehogsCount() const;

 signals:
  void previewIsRendering();
  void previewImageChanged();
  void previewHogCountChanged(int count);
  void gameFinished();
  void previewHedgehogsCountChanged(int previewHedgehogsCount);

 private:
  QQmlEngine* m_engine;
  PreviewImageProvider* m_previewProvider;
  GameConfig m_gameConfig;
  int m_previewHedgehogsCount;
};

#endif  // HWENGINE_H
