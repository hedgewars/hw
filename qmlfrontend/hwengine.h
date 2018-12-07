#ifndef HWENGINE_H
#define HWENGINE_H

#include <QList>
#include <QObject>

#include "engine_interface.h"
#include "game_config.h"

class QQmlEngine;
class EngineInstance;
class PreviewAcceptor;

class HWEngine : public QObject {
  Q_OBJECT

  Q_PROPERTY(int previewHedgehogsCount READ previewHedgehogsCount NOTIFY
                 previewHedgehogsCountChanged)
  Q_PROPERTY(PreviewAcceptor* previewAcceptor READ previewAcceptor WRITE
                 setPreviewAcceptor NOTIFY previewAcceptorChanged)

 public:
  explicit HWEngine(QObject* parent = nullptr);
  ~HWEngine();

  Q_INVOKABLE void getPreview();
  Q_INVOKABLE EngineInstance* runQuickGame();

  int previewHedgehogsCount() const;
  PreviewAcceptor* previewAcceptor() const;

 public slots:
  void setPreviewAcceptor(PreviewAcceptor* previewAcceptor);

 signals:
  void previewIsRendering();
  void previewImageChanged();
  void previewHogCountChanged(int count);
  void gameFinished();
  void previewHedgehogsCountChanged(int previewHedgehogsCount);
  void previewAcceptorChanged(PreviewAcceptor* previewAcceptor);

 private:
  QQmlEngine* m_engine;
  GameConfig m_gameConfig;
  int m_previewHedgehogsCount;
  PreviewAcceptor* m_previewAcceptor;
};

#endif  // HWENGINE_H
