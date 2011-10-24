/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "hwform.h"
#include "hwconsts.h"

#include "HWDataManager.h"

#ifdef _WIN32
#include <Shlobj.h>
#endif
#ifdef __APPLE__
#include "CocoaInitializer.h"
#endif

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

int main(int argc, char *argv[]) {
    HWApplication app(argc, argv);
    app.setAttribute(Qt::AA_DontShowIconsInMenus,false);

    QStringList arguments = app.arguments();
    QMap<QString, QString> parsedArgs;
    {
        QList<QString>::iterator i = arguments.begin();
        while(i != arguments.end()) {
            QString arg = *i;

            QRegExp opt("--(\\S+)=(.+)");
            if(opt.exactMatch(arg)) {
                parsedArgs[opt.cap(1)] = opt.cap(2);
                i = arguments.erase(i);
            } else {
              ++i;
            }
        }
    }

    if(parsedArgs.contains("data-dir")) {
        QFileInfo f(parsedArgs["data-dir"]);
        if(!f.exists()) {
            qWarning() << "WARNING: Cannot open DATA_PATH=" << f.absoluteFilePath();
        }
        *cDataDir = f.absoluteFilePath();
        custom_data = true;
    }

    if(parsedArgs.contains("config-dir")) {
        QFileInfo f(parsedArgs["config-dir"]);
        *cConfigDir = f.absoluteFilePath();
        custom_config = true;
    }

    app.setStyle(new QPlastiqueStyle);

    QDateTime now = QDateTime::currentDateTime();
    srand(now.toTime_t());
    rand();

    Q_INIT_RESOURCE(hedgewars);

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
        // TODO: Uncomment paths as they're implemented
        checkForDir(cfgdir->absolutePath() + "/Data");
        //checkForDir(cfgdir->absolutePath() + "/Data/Forts");
        //checkForDir(cfgdir->absolutePath() + "/Data/Graphics");
        //checkForDir(cfgdir->absolutePath() + "/Data/Graphics/Flags");
        //checkForDir(cfgdir->absolutePath() + "/Data/Graphics/Graves");
        //checkForDir(cfgdir->absolutePath() + "/Data/Graphics/Hats");
        //checkForDir(cfgdir->absolutePath() + "/Data/Maps");
        //checkForDir(cfgdir->absolutePath() + "/Data/Missions");
        //checkForDir(cfgdir->absolutePath() + "/Data/Missions/Campaign");
        //checkForDir(cfgdir->absolutePath() + "/Data/Missions/Training");
        //checkForDir(cfgdir->absolutePath() + "/Data/Sounds");
        //checkForDir(cfgdir->absolutePath() + "/Data/Sounds/voices");
        //checkForDir(cfgdir->absolutePath() + "/Data/Themes");

        // config/save paths
        checkForDir(cfgdir->absolutePath() + "/Demos");
        checkForDir(cfgdir->absolutePath() + "/Saves");
        checkForDir(cfgdir->absolutePath() + "/Screenshots");
        checkForDir(cfgdir->absolutePath() + "/Teams");
        checkForDir(cfgdir->absolutePath() + "/Logs");
    }

    datadir->cd(bindir->absolutePath());
    datadir->cd(*cDataDir);
    if(!datadir->cd("hedgewars/Data")) {
        QMessageBox::critical(0, QMessageBox::tr("Error"),
            QMessageBox::tr("Failed to open data directory:\n%1\n"
                    "Please check your installation").
                    arg(datadir->absolutePath()+"/hedgewars/Data"));
        return 1;
    }

    // copy data/default css files to cfgdir as templates
    QString userCssDir = cfgdir->absolutePath() + "/Data/css";
    if (checkForDir(userCssDir))
    {
        QString defaultCssDir = ":res/css";
        QStringList cssFiles = QDir(defaultCssDir).entryList(QDir::Files);
        foreach (const QString & cssFile, cssFiles)
        {
            QString srcName = datadir->absolutePath()+"/css/"+cssFile;

            if (!QFile::exists(srcName))
                srcName = defaultCssDir+"/"+cssFile;

            QString tmpName = userCssDir + "/template_" + cssFile;
            if (QFile::exists(tmpName))
                QFile::remove(tmpName);

            QFile(srcName).copy(tmpName);
        }
    }

    HWDataManager & dataMgr = HWDataManager::instance();

    {
        QStringList themes;

        themes.append(dataMgr.entryList(
                         "Themes",
                         QDir::AllDirs | QDir::NoDotAndDotDot)
                     );

        QList<QPair<QIcon, QIcon> > icons;

        themes.sort();
        for(int i = themes.size() - 1; i >= 0; --i)
        {
            QString file = dataMgr.findFileForRead(
                QString("Themes/%1/icon.png").arg(themes.at(i))
            );

            if(QFile::exists(file))
            { // load icon
                QPair<QIcon, QIcon> ic;
                ic.first = QIcon(file);

                // load preview icon
                ic.second = QIcon(
                    dataMgr.findFileForRead(
                        QString("Themes/%1/icon@2x.png").arg(themes.at(i))
                    )
                );

                icons.prepend(ic);
            }
            else
            {
                themes.removeAt(i);
            }
        }

        themesModel = new ThemesModel(themes);
        Q_ASSERT(themes.size() == icons.size());
        for(int i = 0; i < icons.size(); ++i)
        {
            themesModel->setData(themesModel->index(i), icons[i].first, Qt::DecorationRole);
            themesModel->setData(themesModel->index(i), icons[i].second, Qt::UserRole);
        }
    }

    mapList = new QStringList(dataMgr.entryList(
                                 QString("Maps"),
                                 QDir::Dirs | QDir::NoDotAndDotDot
                                 )
                             );
 
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

    // load external stylesheet if there is any
    QFile extFile(dataMgr.findFileForRead("css/qt.css"));

    QFile resFile(":/res/css/qt.css");

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
