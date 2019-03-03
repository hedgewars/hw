#include <QDebug>
#include <QGuiApplication>
#include <QLibrary>
#include <QQmlApplicationEngine>

#include "engine_interface.h"
#include "game_view.h"
#include "hwengine.h"
#include "preview_acceptor.h"

namespace Engine {};  // namespace Engine

static QObject* previewacceptor_singletontype_provider(
    QQmlEngine* engine, QJSEngine* scriptEngine) {
  Q_UNUSED(scriptEngine)

  PreviewAcceptor* acceptor = new PreviewAcceptor(engine);
  return acceptor;
}

int main(int argc, char* argv[]) {
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  qmlRegisterSingletonType<PreviewAcceptor>(
      "Hedgewars.Engine", 1, 0, "PreviewAcceptor",
      previewacceptor_singletontype_provider);
  qmlRegisterType<HWEngine>("Hedgewars.Engine", 1, 0, "HWEngine");
  qmlRegisterType<GameView>("Hedgewars.Engine", 1, 0, "GameView");
  qmlRegisterUncreatableType<EngineInstance>("Hedgewars.Engine", 1, 0,
                                             "EngineInstance",
                                             "Create by HWEngine run methods");

  engine.load(QUrl(QLatin1String("qrc:/main.qml")));
  if (engine.rootObjects().isEmpty()) return -1;

  return app.exec();
}
