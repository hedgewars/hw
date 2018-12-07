#include <QDebug>
#include <QGuiApplication>
#include <QLibrary>
#include <QQmlApplicationEngine>

#include "engine_interface.h"
#include "game_view.h"
#include "hwengine.h"
#include "preview_acceptor.h"

namespace Engine {
hedgewars_engine_protocol_version_t* hedgewars_engine_protocol_version;
start_engine_t* start_engine;
generate_preview_t* generate_preview;
cleanup_t* cleanup;
send_ipc_t* send_ipc;
read_ipc_t* read_ipc;
setup_current_gl_context_t* setup_current_gl_context;
render_frame_t* render_frame;
advance_simulation_t* advance_simulation;
};  // namespace Engine

static QObject* previewacceptor_singletontype_provider(
    QQmlEngine* engine, QJSEngine* scriptEngine) {
  Q_UNUSED(scriptEngine)

  PreviewAcceptor* acceptor = new PreviewAcceptor(engine);
  return acceptor;
}

void loadEngineLibrary() {
#ifdef Q_OS_WIN
  QLibrary hwlib("./libhedgewars_engine.dll");
#else
  QLibrary hwlib("./libhedgewars_engine.so");
#endif

  if (!hwlib.load())
    qWarning() << "Engine library not found" << hwlib.errorString();

  Engine::hedgewars_engine_protocol_version =
      reinterpret_cast<Engine::hedgewars_engine_protocol_version_t*>(
          hwlib.resolve("hedgewars_engine_protocol_version"));
  Engine::start_engine =
      reinterpret_cast<Engine::start_engine_t*>(hwlib.resolve("start_engine"));
  Engine::generate_preview = reinterpret_cast<Engine::generate_preview_t*>(
      hwlib.resolve("generate_preview"));
  Engine::cleanup =
      reinterpret_cast<Engine::cleanup_t*>(hwlib.resolve("cleanup"));

  Engine::send_ipc =
      reinterpret_cast<Engine::send_ipc_t*>(hwlib.resolve("send_ipc"));
  Engine::read_ipc =
      reinterpret_cast<Engine::read_ipc_t*>(hwlib.resolve("read_ipc"));

  Engine::setup_current_gl_context =
      reinterpret_cast<Engine::setup_current_gl_context_t*>(
          hwlib.resolve("setup_current_gl_context"));
  Engine::render_frame =
      reinterpret_cast<Engine::render_frame_t*>(hwlib.resolve("render_frame"));
  Engine::advance_simulation = reinterpret_cast<Engine::advance_simulation_t*>(
      hwlib.resolve("advance_simulation"));

  if (Engine::hedgewars_engine_protocol_version)
    qDebug() << "Loaded engine library with protocol version"
             << Engine::hedgewars_engine_protocol_version();
}

int main(int argc, char* argv[]) {
  QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
  QGuiApplication app(argc, argv);

  loadEngineLibrary();

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
