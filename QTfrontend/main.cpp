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

#include "HWApplication.h"

#include <QTranslator>
#include <QLocale>
#include <QRegExp>
#include <QMap>
#include <QSettings>
#include <QStringListModel>
#include <QDate>
#include <QDesktopWidget>
#include <QLabel>
#include <QLibraryInfo>
#include <QStyle>
#include <QStyleFactory>

#include "hwform.h"
#include "hwconsts.h"
#include "newnetclient.h"

#include "DataManager.h"
#include "FileEngine.h"
#include "MessageDialog.h"

#include "SDLInteraction.h"

#ifdef _WIN32
#include <Shlobj.h>
#elif defined __APPLE__
#include "CocoaInitializer.h"

#endif

#ifdef Q_OS_WIN
#include <QSplashScreen>
#endif

// Program resources
#ifdef __APPLE__
static CocoaInitializer * cocoaInit = NULL;
#endif
static FileEngineHandler * engine = NULL;

//Determines the day of easter in year
//from http://aa.usno.navy.mil/faq/docs/easter.php,adapted to C/C++
QDate calculateEaster(long year)
{
    int c, n, k, i, j, l, m, d;

    c = year/100;
    n = year - 19*(year/19);
    k = (c - 17)/25;
    i = c - c/4 - (c - k)/3 + 19*n + 15;
    i = i - 30*(i/30);
    i = i - (i/28)*(1 - (i/28)*(29/(i + 1))*((21 - n)/11));
    j = year + year/4 + i + 2 - c + c/4;
    j = j - 7*(j/7);
    l = i - j;
    m = 3 + (l + 40)/44;
    d = l + 28 - 31*(m / 4);

    return QDate(year, m, d);
}

//Checks season and assigns it to the variable season in "hwconsts.h"
void checkSeason()
{
    QDate date = QDate::currentDate();

    //Christmas?
    if (date.month() == 12 && date.day() >= 24
            && date.day() <= 26)
        season = SEASON_CHRISTMAS;
    //Hedgewars birthday?
    else if (date.month() == 10 && date.day() == 31)
    {
        season = SEASON_HWBDAY;
        years_since_foundation = date.year() - 2004;
    }
    //Easter?
    else if (calculateEaster(date.year()) == date)
        season = SEASON_EASTER;
    else
        season = SEASON_NONE;
}


bool checkForDir(const QString & dir)
{
    QDir tmpdir(dir);
    if (!tmpdir.exists())
        if (!tmpdir.mkpath(dir))
        {
            MessageDialog::ShowErrorMessage(HWApplication::tr("Cannot create directory %1").arg(dir));
            return false;
        }
    return true;
}

// Guaranteed to be the last thing ran in the application's life time.
// Closes resources that need to exist as long as possible.
void closeResources(void)
{
#ifdef __APPLE__
    if (cocoaInit != NULL)
    {
        delete cocoaInit;
        cocoaInit = NULL;
    }
#endif
    if (engine != NULL)
    {
        delete engine;
        engine = NULL;
    }
}

QString getUsage()
{
    return QString(
"%1: hedgewars [%2...] [%3]\n"
"\n"
"%4:\n"
"  --help              %5\n"
"  --config-dir=PATH   %6\n"
"  --data-dir=PATH     %7\n"
"\n"
"%8"
"\n"
).arg(HWApplication::tr("Usage", "command-line"))
.arg(HWApplication::tr("OPTION", "command-line"))
.arg(HWApplication::tr("CONNECTSTRING", "command-line"))
.arg(HWApplication::tr("Options", "command-line"))
.arg(HWApplication::tr("Display this help", "command-line"))
.arg(HWApplication::tr("Custom path for configuration data and user data", "command-line"))
.arg(HWApplication::tr("Custom path to the game data folder", "command-line"))
.arg(HWApplication::tr("Hedgewars can use a %1 (e.g. \"%2\") to connect on start.", "command-line").arg(HWApplication::tr("CONNECTSTRING", "command-line")).arg(QString("hwplay://") + NETGAME_DEFAULT_SERVER));
}

int main(int argc, char *argv[]) {
	/* Qt5 removed motif, plastique.  These are now in qt5-style-plugins which was NOT backported by debian/ubuntu to stable/LTS - windows appears to render best of the remaining options */
	QApplication::setStyle(QStyleFactory::create("windows"));
    // Since we're calling this first, closeResources() will be the last thing called after main() returns.
    atexit(closeResources);

#ifdef __APPLE__
    cocoaInit = new CocoaInitializer(); // Creates the autoreleasepool preventing cocoa object leaks on OS X.
#endif

    SDLInteraction::instance();

    HWApplication app(argc, argv);
	//qDebug() << app.style();
    app.setAttribute(Qt::AA_DontShowIconsInMenus,false);

    // file engine, to be initialized later
    engine = NULL;

    // parse arguments

    QStringList arguments = app.arguments();
    QMap<QString, QString> parsedArgs;
    {
        QList<QString>::iterator i = arguments.begin();
        while(i != arguments.end())
        {
            QString arg = *i;


            QRegExp opt("--(\\S+)=(.+)");
            if(opt.exactMatch(arg))
            {
                parsedArgs[opt.cap(1)] = opt.cap(2);
                i = arguments.erase(i);
            }
            else
            {
                if(arg.startsWith("--")) {
                    if(arg == "--help")
                    {
                        printf("%s", getUsage().toUtf8().constData());
                        return 0;
                    }
                    // argument is something wrong
                    fprintf(stderr, "%s\n\n%s",
                        HWApplication::tr("Malformed option argument: %1", "command-line").arg(arg).toUtf8().constData(),
                        getUsage().toUtf8().constData());
                    return 1;
                }

                // if not starting with --, then always skip
                // (because we can't determine if executable path/call or not - on windows)
                ++i;
            }
        }
    }

    if(parsedArgs.contains("data-dir"))
    {
        QFileInfo f(parsedArgs["data-dir"]);
        parsedArgs.remove("data-dir");
        if(!f.exists())
        {
            qWarning() << "WARNING: Cannot open DATA_PATH=" << f.absoluteFilePath();
        }
        *cDataDir = f.absoluteFilePath();
        custom_data = true;
    }

    if(parsedArgs.contains("config-dir"))
    {
        QFileInfo f(parsedArgs["config-dir"]);
        parsedArgs.remove("config-dir");
        cfgdir->setPath(f.absoluteFilePath());
        custom_config = true;
    }
    else
    {
        cfgdir->setPath(QDir::homePath());
        custom_config = false;
    }

    if (!parsedArgs.isEmpty()) {
        foreach (const QString & key, parsedArgs.keys())
        {
            fprintf(stderr, "%s\n", HWApplication::tr("Unknown option argument: %1", "command-line").arg(QString("--") + key).toUtf8().constData());
        }
        fprintf(stderr, "\n%s", getUsage().toUtf8().constData());
        return 1;
    }

    // end of parameter parsing


#ifdef Q_OS_WIN
    QPixmap pixmap(":/res/splash.png");
    QSplashScreen splash(pixmap);
    splash.show();
#endif

    QDateTime now = QDateTime::currentDateTime();
    srand(now.toTime_t());
    rand();

    Q_INIT_RESOURCE(hedgewars);

    qRegisterMetaType<HWTeam>("HWTeam");

    bindir->cd(QCoreApplication::applicationDirPath());

    if(custom_config == false)
    {
#ifdef __APPLE__
        checkForDir(cfgdir->absolutePath() + "/Library/Application Support/Hedgewars");
        cfgdir->cd("Library/Application Support/Hedgewars");
#elif defined _WIN32
        char path[1024];
        if(!SHGetFolderPathA(0, CSIDL_PERSONAL, NULL, 0, path))
        {
            cfgdir->cd(path);
            checkForDir(cfgdir->absolutePath() + "/Hedgewars");
            cfgdir->cd("Hedgewars");
        }
        else // couldn't retrieve documents folder? almost impossible, but in case fall back to classic path
        {
            checkForDir(cfgdir->absolutePath() + "/.hedgewars");
            cfgdir->cd(".hedgewars");
        }
#else
        checkForDir(cfgdir->absolutePath() + "/.hedgewars");
        cfgdir->cd(".hedgewars");
#endif
    }

    if (checkForDir(cfgdir->absolutePath()))
    {
        // alternative loading/lookup paths
        checkForDir(cfgdir->absolutePath() + "/Data");

        // config/save paths
        checkForDir(cfgdir->absolutePath() + "/Demos");
        checkForDir(cfgdir->absolutePath() + "/Saves");
        checkForDir(cfgdir->absolutePath() + "/Screenshots");
        checkForDir(cfgdir->absolutePath() + "/Teams");
        checkForDir(cfgdir->absolutePath() + "/Logs");
        checkForDir(cfgdir->absolutePath() + "/Videos");
        checkForDir(cfgdir->absolutePath() + "/VideoTemp");
    }

    datadir->cd(bindir->absolutePath());
    datadir->cd(*cDataDir);
    if (!datadir->cd("Data"))
    {
        MessageDialog::ShowFatalMessage(HWApplication::tr("Failed to open data directory:\n%1\n\nPlease check your installation!").arg(datadir->absolutePath()+"/Data"));
        return 1;
    }

    // setup PhysFS
    engine = new FileEngineHandler(argv[0]);
    engine->mount(datadir->absolutePath());
    engine->mount(cfgdir->absolutePath() + "/Data");
    engine->mount(cfgdir->absolutePath());
    engine->setWriteDir(cfgdir->absolutePath());
    engine->mountPacks();

    QTranslator TranslatorHedgewars;
    QTranslator TranslatorQt;
    {
        QSettings settings(DataManager::instance().settingsFileName(), QSettings::IniFormat);
        settings.setIniCodec("UTF-8");

        QString cc = settings.value("misc/locale", QString()).toString();
        if (cc.isEmpty())
        {
            cc = QLocale::system().name();

            // Fallback to current input locale if "C" locale is returned
            if(cc == "C")
                cc = HWApplication::inputMethod()->locale().name();
        }

        // Load locale files into translators
        if (!TranslatorHedgewars.load(QString("physfs://Locale/hedgewars_%1").arg(cc)))
            qWarning("Failed to install Hedgewars translation (%s)", qPrintable(cc));
        if (!TranslatorQt.load(QString("%1/qt_%2").arg(QLibraryInfo::location(QLibraryInfo::TranslationsPath), cc)))
            qWarning("Failed to install Qt translation (%s)", qPrintable(cc));
        app.installTranslator(&TranslatorHedgewars);
        app.installTranslator(&TranslatorQt);
        app.setLayoutDirection(QLocale(cc).textDirection());
    }

#ifdef _WIN32
    // Win32 registry setup (used for external software detection etc.
    // don't set it if running in "portable" mode with a custom config dir)
    if(!custom_config)
    {
        QSettings registry_hklm("HKEY_LOCAL_MACHINE", QSettings::NativeFormat);
        registry_hklm.setValue("Software/Hedgewars/Frontend", bindir->absolutePath().replace("/", "\\") + "\\hedgewars.exe");
        registry_hklm.setValue("Software/Hedgewars/Path", bindir->absolutePath().replace("/", "\\"));
    }
#endif

    QString style = "";
    QString fname;

    checkSeason();
    //For each season, there is an extra stylesheet
    //Todo: change background for easter and birthday
    //(simply replace res/BackgroundBirthday.png and res/BackgroundEaster.png
    //with an appropriate background
    switch (season)
    {
        case SEASON_CHRISTMAS :
            fname = "christmas.css";
            break;
        case SEASON_EASTER :
            fname = "easter.css";
            break;
        case SEASON_HWBDAY :
            fname = "birthday.css";
            break;
        default :
            fname = "qt.css";
            break;
    }

    // load external stylesheet if there is any
    QFile extFile("physfs://css/" + fname);

    QFile resFile(":/res/css/" + fname);

    QFile & file = (extFile.exists() ? extFile : resFile);

    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
        style.append(file.readAll());

    qWarning("Starting Hedgewars %s-r%d (%s)", qPrintable(*cVersionString), cRevisionString->toInt(), qPrintable(*cHashString));

    app.form = new HWForm(NULL, style);
#ifdef Q_OS_WIN
    splash.finish(app.form);
#endif
    app.form->show();

    if (app.urlString)
        app.fakeEvent();
    return app.exec();
}
