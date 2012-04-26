/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include "HWApplication.h"

#include <QTranslator>
#include <QLocale>
#include <QMessageBox>
#include <QPlastiqueStyle>
#include <QRegExp>
#include <QMap>
#include <QSettings>
#include <QStringListModel>
#include <QDate>

#include "hwform.h"
#include "hwconsts.h"
#include "newnetclient.h"

#include "DataManager.h"

#ifdef _WIN32
#include <Shlobj.h>
#endif
#ifdef __APPLE__
#include "CocoaInitializer.h"
#endif


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
    QDir tmpdir;
    if (!tmpdir.exists(dir))
        if (!tmpdir.mkdir(dir))
        {
            QMessageBox::critical(0,
                                  QObject::tr("Error"),
                                  QObject::tr("Cannot create directory %1").arg(dir),
                                  QObject::tr("OK"));
            return false;
        }
    return true;
}

int main(int argc, char *argv[])
{
    HWApplication app(argc, argv);
    app.setAttribute(Qt::AA_DontShowIconsInMenus,false);

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
                ++i;
            }
        }
    }

    if(parsedArgs.contains("data-dir"))
    {
        QFileInfo f(parsedArgs["data-dir"]);
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
        *cConfigDir = f.absoluteFilePath();
        custom_config = true;
    }

    app.setStyle(new QPlastiqueStyle);

    QDateTime now = QDateTime::currentDateTime();
    srand(now.toTime_t());
    rand();

    Q_INIT_RESOURCE(hedgewars);

    qRegisterMetaType<HWTeam>("HWTeam");

    bindir->cd("bin"); // workaround over NSIS installer

    if(cConfigDir->length() == 0)
        cfgdir->setPath(cfgdir->homePath());
    else
        cfgdir->setPath(*cConfigDir);

    if(cConfigDir->length() == 0)
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
    }

    datadir->cd(bindir->absolutePath());
    datadir->cd(*cDataDir);
    if(!datadir->cd("hedgewars/Data"))
    {
        QMessageBox::critical(0, QMessageBox::tr("Error"),
                              QMessageBox::tr("Failed to open data directory:\n%1\n"
                                              "Please check your installation").
                              arg(datadir->absolutePath()+"/hedgewars/Data"));
        return 1;
    }

    DataManager & dataMgr = DataManager::instance();

    scriptList = new QStringList(dataMgr.entryList(
                                     QString("Scripts/Multiplayer"),
                                     QDir::Files,
                                     QStringList("*.lua")
                                 )
                                );

    QTranslator Translator;
    {
        QSettings settings(cfgdir->absolutePath() + "/hedgewars.ini", QSettings::IniFormat);
        QString cc = settings.value("misc/locale", QString()).toString();
        if(cc.isEmpty())
            cc = QLocale::system().name();

        // load locale file into translator
        Translator.load(
            dataMgr.findFileForRead(
                QString("Locale/hedgewars_" + cc)
            )
        );
        app.installTranslator(&Translator);
    }

#ifdef _WIN32
    // Win32 registry setup (used for xfire detection etc. - don't set it if we're running in "portable" mode with a custom config dir)
    if(!custom_config)
    {
        QSettings registry_hklm("HKEY_LOCAL_MACHINE", QSettings::NativeFormat);
        registry_hklm.setValue("Software/Hedgewars/Frontend", bindir->absolutePath().replace("/", "\\") + "\\hedgewars.exe");
        registry_hklm.setValue("Software/Hedgewars/Path", bindir->absolutePath().replace("/", "\\"));
    }
#endif
#ifdef __APPLE__
    // this creates the autoreleasepool that prevents leaking
    CocoaInitializer initializer;
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
    }

    // load external stylesheet if there is any
    QFile extFile(dataMgr.findFileForRead("css/" + fname));

    QFile resFile(":/res/css/" + fname);

    QFile & file = (extFile.exists()?extFile:resFile);

    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QTextStream in(&file);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            if(!line.isEmpty())
                style.append(line);
        }
    }

    app.form = new HWForm(NULL, style);
    app.form->show();
    return app.exec();
}
