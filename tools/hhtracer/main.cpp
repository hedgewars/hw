#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "tracer.h"

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  // Tracer tracer;
  // engine.rootContext()->setContextProperty(QStringLiteral("tracer"),
  // &tracer);

  QObject::connect(
      &engine, &QQmlApplicationEngine::objectCreationFailed, &app,
      []() { QCoreApplication::exit(-1); }, Qt::QueuedConnection);
  engine.loadFromModule("hhtracer", "Main");

  return app.exec();
}
