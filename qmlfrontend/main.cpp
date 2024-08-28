#include <QDebug>
#include <QGuiApplication>
#include <QLibrary>
#include <QQmlApplicationEngine>

#include "engine_interface.h"
#include "game_view.h"
#include "hwengine.h"
#include "net_session.h"
#include "preview_acceptor.h"

static QObject* previewacceptor_singletontype_provider(
    QQmlEngine* engine, QJSEngine* scriptEngine) {
  Q_UNUSED(scriptEngine)

  PreviewAcceptor* acceptor = new PreviewAcceptor(engine);
  return acceptor;
}

int main(int argc, char* argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  qRegisterMetaType<Engine::SimpleEventType>();
  qRegisterMetaType<Engine::LongEventType>();
  qRegisterMetaType<Engine::LongEventState>();
  qRegisterMetaType<Engine::PositionedEventType>();

  qmlRegisterSingletonType<PreviewAcceptor>(
      "Hedgewars.Engine", 1, 0, "PreviewAcceptor",
      previewacceptor_singletontype_provider);
  qmlRegisterType<HWEngine>("Hedgewars.Engine", 1, 0, "HWEngine");
  qmlRegisterType<GameView>("Hedgewars.Engine", 1, 0, "GameView");
  qmlRegisterType<NetSession>("Hedgewars.Engine", 1, 0, "NetSession");
  qmlRegisterUncreatableType<EngineInstance>(
      "Hedgewars.Engine", 1, 0, "EngineInstance",
      QStringLiteral("Create by HWEngine run methods"));

  qmlRegisterUncreatableMetaObject(Engine::staticMetaObject, "Hedgewars.Engine",
                                   1, 0, "Engine",
                                   QStringLiteral("Namespace: only enums"));

  engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
  if (engine.rootObjects().isEmpty()) return -1;

  return app.exec();
}
