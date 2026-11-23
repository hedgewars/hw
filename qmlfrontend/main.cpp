#include <QDebug>
#include <QGuiApplication>
#include <QLibrary>
#include <QQmlApplicationEngine>
#include <QThread>
#include <iostream>

#include "engine_interface.h"
#include "game_view.h"
#include "hwengine.h"
#include "net_session.h"
#include "preview_acceptor.h"

static QObject* previewacceptor_singletontype_provider(QQmlEngine* engine, QJSEngine* scriptEngine)
{
  Q_UNUSED(scriptEngine)

  PreviewAcceptor* acceptor = new PreviewAcceptor(engine);
  return acceptor;
}

QString hedgewarsFormatLogMessage(QtMsgType type,
                                  const QMessageLogContext& context,
                                  const QString& str)
{
  const auto threadId = QThread::currentThreadId();
  auto file = QByteArray(context.file);
  auto function = QByteArray(context.function);
  auto message = str;

  { // message transformation
    if (message.startsWith(QString::fromLatin1(file))) {
      message = message.mid(file.length());

      const auto lineString = QStringLiteral(":%1").arg(context.line);

      if (message.startsWith(lineString)) {
        message = message.mid(lineString.length());
      }

      message = QStringLiteral("[Qt] ") + message;
    }
  }

  { // file path prefix simplification
    if (file.startsWith("file://")) {
      file = file.mid(7);
    }

    if (file.startsWith("qrc:")) {
      file = file.mid(4);
    }

    while (file.startsWith("../")) {
      file = file.mid(3);
    }
  }
  { // only leave function name
    if (const auto p = function.lastIndexOf('('); p >= 0) {
      function = function.left(p);
    }
    if (const auto p = function.lastIndexOf(':'); p >= 0) {
      function = function.mid(p + 1);
    }
  }

  { // file path shortening
    if (auto r = file.lastIndexOf('/'); r >= 0) {
      auto i = file.lastIndexOf('/', r - 2);
      auto j = file.lastIndexOf('_', r - 2);

      while (r > 0) {
        if (j > i) {
          file.remove(j + 2, r - j - 2);
          r = j;
          j = file.lastIndexOf('_', r - 2);
        } else if (i == -1) {
          file.remove(1, r - 1);
          r = i;
        } else {
          file.remove(i + 2, r - i - 2);
          r = i;
          i = file.lastIndexOf('/', r - 2);
        }
      }
    }
  }

  static constexpr std::array<const char*, 5> levels{".", "!", "^", "x", "i"};

  return QStringLiteral("%1 %6 %2 (%3 %4:%5) [%8] %7")
      .arg(QString::fromUtf8(levels[type]))
      .arg(reinterpret_cast<quintptr>(threadId))
      .arg(QString::fromUtf8(function.constData()), 20)
      .arg(QString::fromUtf8(file.constData()), 24)
      .arg(context.line, 3, 10, QChar('0'))
      .arg(QDateTime::currentDateTimeUtc().toString(QStringLiteral("MM-dd HH:mm:ss.zzz")), message)
      .arg(QString::fromLatin1(context.category), 16);
}

void hedgewarsMessageOutput(QtMsgType type, const QMessageLogContext& context, const QString& msg)
{
  static const auto haveMessagePattern = qEnvironmentVariableIsSet("QT_MESSAGE_PATTERN");

  const auto outputMessage = haveMessagePattern ? qFormatLogMessage(type, context, msg)
                                                : hedgewarsFormatLogMessage(type, context, msg);

  std::cerr << qPrintable(outputMessage) << std::endl;
}

int main(int argc, char* argv[])
{
  qInstallMessageHandler(hedgewarsMessageOutput);

  QGuiApplication app(argc, argv);

  QQmlApplicationEngine engine;

  qRegisterMetaType<Engine::SimpleEventType>();
  qRegisterMetaType<Engine::LongEventType>();
  qRegisterMetaType<Engine::LongEventState>();
  qRegisterMetaType<Engine::PositionedEventType>();

  qmlRegisterSingletonType<PreviewAcceptor>("Hedgewars.Engine",
                                            1,
                                            0,
                                            "PreviewAcceptor",
                                            previewacceptor_singletontype_provider);
  qmlRegisterType<HWEngine>("Hedgewars.Engine", 1, 0, "HWEngine");
  qmlRegisterType<GameView>("Hedgewars.Engine", 1, 0, "GameView");
  qmlRegisterType<NetSession>("Hedgewars.Engine", 1, 0, "NetSession");
  qmlRegisterUncreatableType<EngineInstance>("Hedgewars.Engine",
                                             1,
                                             0,
                                             "EngineInstance",
                                             QStringLiteral("Create by HWEngine run methods"));

  qmlRegisterUncreatableMetaObject(Engine::staticMetaObject,
                                   "Hedgewars.Engine",
                                   1,
                                   0,
                                   "Engine",
                                   QStringLiteral("Namespace: only enums"));

  engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
  if (engine.rootObjects().isEmpty())
    return -1;

  return app.exec();
}
