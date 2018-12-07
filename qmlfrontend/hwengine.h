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
  Q_PROPERTY(QString engineLibrary READ engineLibrary WRITE setEngineLibrary
                 NOTIFY engineLibraryChanged)

 public:
  explicit HWEngine(QObject* parent = nullptr);
  ~HWEngine();

  Q_INVOKABLE void getPreview();
  Q_INVOKABLE EngineInstance* runQuickGame();

  int previewHedgehogsCount() const;
  PreviewAcceptor* previewAcceptor() const;
  QString engineLibrary() const;

 public slots:
  void setPreviewAcceptor(PreviewAcceptor* previewAcceptor);
  void setEngineLibrary(const QString& engineLibrary);

 signals:
  void previewIsRendering();
  void previewImageChanged();
  void previewHogCountChanged(int count);
  void gameFinished();
  void previewHedgehogsCountChanged(int previewHedgehogsCount);
  void previewAcceptorChanged(PreviewAcceptor* previewAcceptor);
  void engineLibraryChanged(const QString& engineLibrary);

 private:
  QQmlEngine* m_engine;
  GameConfig m_gameConfig;
  int m_previewHedgehogsCount;
  PreviewAcceptor* m_previewAcceptor;
  QString m_engineLibrary;
};

#endif  // HWENGINE_H
