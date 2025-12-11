/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QDate>
#include <QLabel>
#include <QLibraryInfo>
#include <QLocale>
#include <QMap>
#include <QRegularExpression>
#include <QSettings>
#include <QStringListModel>
#include <QStyle>
#include <QStyleFactory>
#include <QTranslator>
#include <iostream>

#include "DataManager.h"
#include "HWApplication.h"
#include "MessageDialog.h"
#include "SDLInteraction.h"
#include "hwconsts.h"
#include "hwform.h"
#include "physfs_integration.h"

#ifdef _WIN32
#include <Shlobj.h>
#elif defined __APPLE__
#include "CocoaInitializer.h"

#endif

#ifdef Q_OS_WIN
#include <QSplashScreen>
#endif

#include <QMessageBox>

// Program resources
#ifdef __APPLE__
static CocoaInitializer *cocoaInit = NULL;
#endif

// Determines the day of easter in year
// from http://aa.usno.navy.mil/faq/docs/easter.php,adapted to C/C++
QDate calculateEaster(long year) {
  int c, n, k, i, j, l, m, d;

  c = year / 100;
  n = year - 19 * (year / 19);
  k = (c - 17) / 25;
  i = c - c / 4 - (c - k) / 3 + 19 * n + 15;
  i = i - 30 * (i / 30);
  i = i - (i / 28) * (1 - (i / 28) * (29 / (i + 1)) * ((21 - n) / 11));
  j = year + year / 4 + i + 2 - c + c / 4;
  j = j - 7 * (j / 7);
  l = i - j;
  m = 3 + (l + 40) / 44;
  d = l + 28 - 31 * (m / 4);

  return QDate(year, m, d);
}

// Checks season and assigns it to the variable season in "hwconsts.h"
void checkSeason() {
  QDate date = QDate::currentDate();

  // Christmas?
  if (date.month() == 12 && date.day() >= 24 && date.day() <= 26)
    season = SEASON_CHRISTMAS;
  // Hedgewars birthday?
  else if (date.month() == 10 && date.day() == 31) {
    season = SEASON_HWBDAY;
    years_since_foundation = date.year() - 2004;
  } else if (date.month() == 4 && date.day() == 1) {
    season = SEASON_APRIL1;
  }
  // Easter?
  else if (calculateEaster(date.year()) == date)
    season = SEASON_EASTER;
  else
    season = SEASON_NONE;
}

bool checkForDir(const QString &dir) {
  QDir tmpdir(dir);
  if (!tmpdir.exists() && !tmpdir.mkpath(dir)) {
    MessageDialog::ShowErrorMessage(
        HWApplication::tr("Cannot create directory %1").arg(dir));
    return false;
  }
  return true;
}

// Guaranteed to be the last thing ran in the application's life time.
// Closes resources that need to exist as long as possible.
void closeResources(void) {
#ifdef __APPLE__
  if (cocoaInit != NULL) {
    delete cocoaInit;
    cocoaInit = NULL;
  }
#endif
}

// Simple Message handler that suppresses Qt debug and info messages (qDebug,
// qInfo). Used when printing command line help (--help) or related error to
// keep console clean.
void restrictedMessageHandler(QtMsgType type, const QMessageLogContext &context,
                              const QString &msg) {
  Q_UNUSED(context)
  QByteArray localMsg = msg.toLocal8Bit();
  switch (type) {
    case QtWarningMsg:
    case QtCriticalMsg:
    case QtFatalMsg:
      fprintf(stderr, "%s\n", localMsg.constData());
      break;
    default:
      break;
  }
}

QString hedgewarsFormatLogMessage(QtMsgType type,
                                  const QMessageLogContext &context,
                                  const QString &str) {
  const auto threadId = QThread::currentThreadId();
  auto file = QByteArray(context.file);
  auto function = QByteArray(context.function);
  auto message = str;

  {  // message transformation
    if (message.startsWith(QString::fromLatin1(file))) {
      message = message.mid(file.length());

      const auto lineString = QStringLiteral(":%1").arg(context.line);

      if (message.startsWith(lineString)) {
        message = message.mid(lineString.length());
      }

      message = QStringLiteral("[Qt] ") + message;
    }
  }

  {  // file path prefix simplification
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
  {  // only leave function name
    if (const auto p = function.lastIndexOf('('); p >= 0) {
      function = function.left(p);
    }
    if (const auto p = function.lastIndexOf(':'); p >= 0) {
      function = function.mid(p + 1);
    }
  }

  {  // file path shortening
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

  static constexpr std::array<const char *, 5> levels{".", "!", "^", "x", "i"};

  return QStringLiteral("%1 %6 %2 (%3 %4:%5) [%8] %7")
      .arg(QString::fromUtf8(levels[type]))
      .arg(reinterpret_cast<quintptr>(threadId))
      .arg(QString::fromUtf8(function.constData()), 24)
      .arg(QString::fromUtf8(file.constData()), 40)
      .arg(context.line, 3, 10, QChar('0'))
      .arg(QDateTime::currentDateTimeUtc().toString(
               QStringLiteral("MM-dd HH:mm:ss.zzz")),
           message)
      .arg(QString::fromLatin1(context.category), 16);
}

void hedgewarsMessageOutput(QtMsgType type, const QMessageLogContext &context,
                            const QString &msg) {
  static const auto haveMessagePattern =
      qEnvironmentVariableIsSet("QT_MESSAGE_PATTERN");

  const auto outputMessage =
      haveMessagePattern ? qFormatLogMessage(type, context, msg)
                         : hedgewarsFormatLogMessage(type, context, msg);

  std::cerr << qPrintable(outputMessage) << std::endl;
}

QString getUsage() {
  return QString(
             "%1: hedgewars [%2...] [%3]\n"
             "\n"
             "%4:\n"
             "  --help              %5\n"
             "  --config-dir=PATH   %6\n"
             "  --data-dir=PATH     %7\n"
             "\n"
             "%8"
             "\n")
      .arg(HWApplication::tr("Usage", "command-line"),
           HWApplication::tr("OPTION", "command-line"),
           HWApplication::tr("CONNECTSTRING", "command-line"),
           HWApplication::tr("Options", "command-line"),
           HWApplication::tr("Display this help", "command-line"),
           HWApplication::tr("Custom path for configuration data and user data",
                             "command-line"),
           HWApplication::tr("Custom path to the game data folder",
                             "command-line"),
           HWApplication::tr(
               "Hedgewars can use a %1 (e.g. \"%2\") to connect on start.",
               "command-line")
               .arg(HWApplication::tr("CONNECTSTRING", "command-line"),
                    QStringLiteral("hwplay://") + NETGAME_DEFAULT_SERVER));
}

int main(int argc, char *argv[]) {
  qInstallMessageHandler(hedgewarsMessageOutput);

  cfgdir.setPath(QDir::homePath());

  // Since we're calling this first, closeResources() will be the last thing
  // called after main() returns.
  atexit(closeResources);

#ifdef __APPLE__
  cocoaInit = new CocoaInitializer();  // Creates the autoreleasepool preventing
                                       // cocoa object leaks on OS X.
#endif

  HWApplication app(argc, argv);
  app.setAttribute(Qt::AA_DontShowIconsInMenus, false);

  /*
  This is for messages frelated to translatable command-line arguments.
  If it is non-zero, will print out a message after loading locale
  and exit.
  */
  enum cmdMsgStateEnum {
    cmdMsgNone,
    cmdMsgHelp,
    cmdMsgMalformedArg,
    cmdMsgUnknownArg,
  };
  enum cmdMsgStateEnum cmdMsgState = cmdMsgNone;
  QString cmdMsgStateStr;

  // parse arguments
  QStringList arguments = app.arguments();
  QMap<QString, QString> parsedArgs;
  {
    QList<QString>::iterator i = arguments.begin();
    while (i != arguments.end()) {
      QString arg = *i;

      QRegularExpression opt(QStringLiteral(R"(^--(\S+)=(.+)$)"));
      auto match = opt.match(arg);
      if (match.hasMatch()) {
        parsedArgs[match.captured(1)] = match.captured(2);
        i = arguments.erase(i);
      } else {
        if (arg.startsWith(QLatin1String("--"))) {
          if (arg == QLatin1String("--help")) {
            cmdMsgState = cmdMsgHelp;
            qInstallMessageHandler(restrictedMessageHandler);
          } else {
            // argument is something wrong
            cmdMsgState = cmdMsgMalformedArg;
            cmdMsgStateStr = arg;
            qInstallMessageHandler(restrictedMessageHandler);
            break;
          }
        }

        // if not starting with --, then always skip
        // (because we can't determine if executable path/call or not - on
        // windows)
        ++i;
      }
    }
  }

  if (cmdMsgState == cmdMsgNone) {
    if (parsedArgs.contains(QStringLiteral("data-dir"))) {
      QFileInfo f(parsedArgs[QStringLiteral("data-dir")]);
      parsedArgs.remove(QStringLiteral("data-dir"));
      if (!f.exists()) {
        qWarning() << "WARNING: Cannot open data-dir=" << f.absoluteFilePath();
      }
      cDataDir = f.absoluteFilePath();
      custom_data = true;
    }

    if (parsedArgs.contains(QStringLiteral("config-dir"))) {
      QFileInfo f(parsedArgs[QStringLiteral("config-dir")]);
      parsedArgs.remove(QStringLiteral("config-dir"));
      cfgdir.setPath(f.absoluteFilePath());
      custom_config = true;
    } else {
      custom_config = false;
    }

    if (!parsedArgs.isEmpty()) {
      cmdMsgState = cmdMsgUnknownArg;
      qInstallMessageHandler(restrictedMessageHandler);
    }

    // end of parameter parsing

    // Select Qt style
    QStyle *coreStyle;
    coreStyle = QStyleFactory::create(QStringLiteral("Windows"));
    if (coreStyle != 0) {
      QApplication::setStyle(coreStyle);
      qDebug("Qt style set: Windows");
    } else {
      // Windows style should not be missing in Qt5 Base. If it does, something
      // went terribly wrong!
      qWarning("No Qt style could be set! Using the default one.");
    }
  }

#ifdef Q_OS_WIN
  // Splash screen for Windows
  QPixmap pixmap(":/res/splash.png");
  QSplashScreen splash(pixmap);
  if (cmdMsgState == cmdMsgNone) {
    splash.show();
  }
#endif

  QDateTime now = QDateTime::currentDateTime();

  Q_INIT_RESOURCE(hedgewars);

  qRegisterMetaType<HWTeam>("HWTeam");

  bindir.cd(QCoreApplication::applicationDirPath());

  if (custom_config == false) {
#ifdef __APPLE__
    checkForDir(cfgdir->absolutePath() +
                "/Library/Application Support/Hedgewars");
    cfgdir->cd("Library/Application Support/Hedgewars");
#elif defined _WIN32
    wchar_t path[MAX_PATH];
    if (SHGetFolderPathW(0, CSIDL_PERSONAL, NULL, 0, path) == S_OK) {
      cfgdir->cd(QString::fromWCharArray(path));
      checkForDir(cfgdir->absolutePath() + "/Hedgewars");
      cfgdir->cd("Hedgewars");
    } else  // couldn't retrieve documents folder? almost impossible, but in
            // case fall back to classic path
    {
      checkForDir(cfgdir->absolutePath() + "/.hedgewars");
      cfgdir->cd(".hedgewars");
    }
#else
    checkForDir(cfgdir.absolutePath() + QStringLiteral("/.hedgewars"));
    cfgdir.cd(QStringLiteral(".hedgewars"));
#endif
  }

  if (checkForDir(cfgdir.absolutePath())) {
    QStringList otherPaths{// alternative loading/lookup paths
                           "/Data",
                           // config/save paths
                           "/Demos", "/DrawnMaps", "/Saves", "/Screenshots",
                           "/Teams", "/Logs", "/Videos", "/VideoTemp",
                           "/VideoThumbnails"};

    for (auto path : otherPaths) {
      checkForDir(cfgdir.absolutePath() + path);
    }
  }

  datadir.cd(bindir.absolutePath());
  datadir.cd(cDataDir);
  if (!datadir.cd(QStringLiteral("Data"))) {
    MessageDialog::ShowFatalMessage(
        HWApplication::tr("Failed to open data directory:\n%1\n\nPlease "
                          "check your installation!")
            .arg(datadir.absolutePath() + QStringLiteral("/Data")));
    return 1;
  }

  bool isProbablyNewPlayer = false;

  auto &physfs = PhysFsManager::instance();
  physfs.init(argv[0]);
  physfs.mount(datadir.absolutePath());
  physfs.mount(cfgdir.absolutePath() + QStringLiteral("/Data"));
  physfs.mount(cfgdir.absolutePath());
  physfs.setWriteDir(cfgdir.absolutePath());
  physfs.mountPacks();

  QTranslator TranslatorHedgewars;
  QTranslator TranslatorQt;
  QSettings settings(DataManager::instance().settingsFileName(),
                     QSettings::IniFormat);
  {
    QString cc = settings.value("misc/locale", QString()).toString();
    if (cc.isEmpty()) {
      cc = QLocale::system().name();
      qDebug("Detected system locale: %s", qPrintable(cc));

      // Fallback to current input locale if "C" locale is returned
      if (cc == QLatin1String("C"))
        cc = HWApplication::inputMethod()->locale().name();
    } else {
      qDebug("Configured frontend locale: %s", qPrintable(cc));
    }
    QLocale::setDefault(QLocale{cc});
    QString defaultLocaleName = QLocale().name();
    qDebug("Frontend uses locale: %s", qPrintable(defaultLocaleName));

    if (defaultLocaleName != QLatin1String("C")) {
      // Load locale files into translators
      if (!TranslatorHedgewars.load(QLocale(), QStringLiteral("hedgewars"),
                                    QStringLiteral("_"),
                                    QStringLiteral("physfs://Locale")))
        qWarning("Failed to install Hedgewars translation (%s)",
                 qPrintable(defaultLocaleName));
      if (!TranslatorQt.load(
              QLocale(), QStringLiteral("qt"), QStringLiteral("_"),
              QString(QLibraryInfo::path(QLibraryInfo::TranslationsPath))))
        qWarning("Failed to install Qt translation (%s)",
                 qPrintable(defaultLocaleName));
      app.installTranslator(&TranslatorHedgewars);
      app.installTranslator(&TranslatorQt);
    }
    app.setLayoutDirection(QLocale().textDirection());

    // Handle command line messages
    switch (cmdMsgState) {
      case cmdMsgHelp: {
        printf("%s", getUsage().toUtf8().constData());
        return 0;
      }
      case cmdMsgMalformedArg: {
        fprintf(
            stderr, "%s\n\n%s",
            HWApplication::tr("Malformed option argument: %1", "command-line")
                .arg(cmdMsgStateStr)
                .toUtf8()
                .constData(),
            getUsage().toUtf8().constData());
        return 1;
      }
      case cmdMsgUnknownArg: {
        for (auto key : parsedArgs.keys()) {
          fprintf(
              stderr, "%s\n",
              HWApplication::tr("Unknown option argument: %1", "command-line")
                  .arg(QStringLiteral("--") + key)
                  .toUtf8()
                  .constData());
        }
        fprintf(stderr, "\n%s", getUsage().toUtf8().constData());
        return 1;
      }
      default: {
        break;
      }
    }

    // Heuristic to figure out if the user is (probably) a first-time player.
    // If nickname is not set, then probably yes.
    // The hidden setting firstLaunch is, if present, used to force HW to
    // treat iself as if it were launched the first time.
    QString nick = settings.value("net/nick", QString()).toString();
    if (settings.contains("frontend/firstLaunch")) {
      isProbablyNewPlayer = settings.value("frontend/firstLaunch").toBool();
    } else {
      isProbablyNewPlayer = nick.isNull();
    }

    // Set firstLaunch to false to make sure we remember we have been launched
    // before.
    settings.setValue("frontend/firstLaunch", false);
  }

#ifdef _WIN32
  // Win32 registry setup (used for external software detection etc.
  // don't set it if running in "portable" mode with a custom config dir)
  if (!custom_config) {
    QSettings registry_hklm("HKEY_LOCAL_MACHINE", QSettings::NativeFormat);
    registry_hklm.setValue(
        "Software/Hedgewars/Frontend",
        bindir->absolutePath().replace("/", "\\") + "\\hedgewars.exe");
    registry_hklm.setValue("Software/Hedgewars/Path",
                           bindir->absolutePath().replace("/", "\\"));
  }
#endif

  SDLInteraction::instance();

  QString style;
  QString fname;

  bool holidaySilliness =
      settings.value("misc/holidaySilliness", true).toBool();
  if (holidaySilliness)
    checkSeason();
  else
    season = SEASON_NONE;

  // For each season, there is an extra stylesheet.
  // TODO: change background for easter
  // (simply replace res/BackgroundEaster.png
  // with an appropriate background).
  switch (season) {
    case SEASON_CHRISTMAS:
      fname = QStringLiteral("christmas.css");
      break;
    case SEASON_APRIL1:
      fname = QStringLiteral("april1.css");
      break;
    case SEASON_EASTER:
      fname = QStringLiteral("easter.css");
      break;
    case SEASON_HWBDAY:
      fname = QStringLiteral("birthday.css");
      break;
    default:
      fname = QStringLiteral("qt.css");
      break;
  }

  // load external stylesheet if there is any
  {
    PhysFsFile extFile(QStringLiteral("/css/") + fname);
    QFile resFile(QStringLiteral(":/res/css/") + fname);

    if (extFile.exists()) {
      if (extFile.open(QIODevice::ReadOnly | QIODevice::Text))
        style.append(extFile.readAll());
    } else {
      if (resFile.open(QIODevice::ReadOnly | QIODevice::Text))
        style.append(resFile.readAll());
    };
  }

  qWarning("Starting Hedgewars %s-r%d (%s)", qPrintable(cVersionString),
           cRevisionString.toInt(), qPrintable(cHashString));

  app.form = new HWForm(NULL, style);
#ifdef Q_OS_WIN
  if (cmdMsgState == cmdMsgNone) splash.finish(app.form);
#endif
  app.form->show();

  // Show welcome message for (suspected) first-time player and
  // point towards the Training menu.
  if (isProbablyNewPlayer) {
    QMessageBox questionTutorialMsg(app.form);
    questionTutorialMsg.setIcon(QMessageBox::Question);
    questionTutorialMsg.setWindowTitle(QMessageBox::tr("Welcome to Hedgewars"));
    questionTutorialMsg.setText(
        QMessageBox::tr("Welcome to Hedgewars!\n\nYou seem to be new around "
                        "here. Would you like to play some training missions "
                        "first to learn the basics of Hedgewars?"));
    questionTutorialMsg.setTextFormat(Qt::PlainText);
    questionTutorialMsg.setWindowModality(Qt::WindowModal);
    questionTutorialMsg.addButton(QMessageBox::Yes);
    questionTutorialMsg.addButton(QMessageBox::No);

    int answer = questionTutorialMsg.exec();
    if (answer == QMessageBox::Yes) {
      app.form->GoToTraining();
    }
  }

  if (app.urlString) app.fakeEvent();
  auto result = app.exec();

  physfs.deinit();

  return result;
}
