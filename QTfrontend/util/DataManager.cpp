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

/**
 * @file
 * @brief DataManager class implementation
 */

#include <QMap>
#include <QStringList>
#include <QStandardItemModel>
#include <QFileInfo>
#include <QSettings>
#include <QColor>

#include <SDL2/SDL.h>

#include "hwconsts.h"
#include "HWApplication.h"
#include "sdlkeys.h"
#include "KeyMap.h"
#include "physfs.h"

#include "DataManager.h"

#include "GameStyleModel.h"
#include "HatModel.h"
#include "MapModel.h"
#include "ThemeModel.h"

DataManager::DataManager()
{
    m_hatModel = NULL;
    m_staticMapModel = NULL;
    m_missionMapModel = NULL;
    m_themeModel = NULL;
    m_colorsModel = NULL;
    m_bindsModel = NULL;
    m_gameStyleModel = NULL;
}


DataManager & DataManager::instance()
{
    static DataManager instance;
    return instance;
}


QStringList DataManager::entryList(
    const QString & subDirectory,
    QDir::Filters filters,
    const QStringList & nameFilters,
    bool withDLC
) const
{
    QDir tmpDir(QString("physfs://%1").arg(subDirectory));
    QStringList result = tmpDir.entryList(nameFilters, filters);

    // sort case-insensitive
    QMap<QString, QString> sortedFileNames;
    QString absolutePath = datadir->absolutePath().toLocal8Bit().data();
    foreach ( QString fn, result)
    {
        // Filter out DLC entries if desired
        QString realDir = PHYSFS_getRealDir(QString(subDirectory + "/" + fn).toLocal8Bit().data());
        if(withDLC || realDir == absolutePath)
            sortedFileNames.insert(fn.toLower(), fn);
    }
    result = sortedFileNames.values();

    return result;
}

GameStyleModel * DataManager::gameStyleModel()
{
    if (m_gameStyleModel == NULL) {
        m_gameStyleModel = new GameStyleModel();
        m_gameStyleModel->loadGameStyles();
    }
    return m_gameStyleModel;
}

HatModel * DataManager::hatModel()
{
    if (m_hatModel == NULL) {
        m_hatModel = new HatModel();
        m_hatModel->loadHats();
    }
    return m_hatModel;
}

MapModel * DataManager::staticMapModel()
{
    if (m_staticMapModel == NULL) {
        m_staticMapModel = new MapModel(MapModel::StaticMap, this);
    }
    return m_staticMapModel;
}

MapModel * DataManager::missionMapModel()
{
    if (m_missionMapModel == NULL) {
        m_missionMapModel = new MapModel(MapModel::MissionMap, this);
    }
    return m_missionMapModel;
}

ThemeModel * DataManager::themeModel()
{
    if (m_themeModel == NULL) {
        m_themeModel = new ThemeModel();
    }
    return m_themeModel;
}

QStandardItemModel * DataManager::colorsModel()
{
    if(m_colorsModel == NULL)
    {
        m_colorsModel = new QStandardItemModel();

        int i = 0;
        while(colors[i])
        {
            QStandardItem * item = new QStandardItem();
            item->setData(QColor(colors[i]));
            m_colorsModel->appendRow(item);
            ++i;
        }
    }

    return m_colorsModel;
}

QStandardItemModel * DataManager::bindsModel()
{
    KeyMap km = KeyMap::instance();
    if(m_bindsModel == NULL)
    {
        m_bindsModel = new QStandardItemModel();

        QStandardItem * firstItem = new QStandardItem();
        firstItem->setData(tr("Use Default"), Qt::DisplayRole);
        firstItem->setData("default", Qt::UserRole + 1);
        m_bindsModel->appendRow(firstItem);

        for(int j = 0; sdlkeys[j][1][0] != '\0'; j++)
        {
            QStandardItem * item = new QStandardItem();
            QString keyId = QString(sdlkeys[j][0]);
            QString keyDisplay;
            bool isKeyboard = !QString(sdlkeys[j][1]).contains(": ");
            if (keyId == "none" || (!isKeyboard))
                keyDisplay = HWApplication::translate("binds (keys)", sdlkeys[j][1]);
            else
                // Get key name with respect to keyboard layout
                keyDisplay = QString(SDL_GetKeyName(SDL_GetKeyFromScancode(km.getScancodeFromKeyname(sdlkeys[j][0]))));

            bool kbFallback = keyDisplay.trimmed().isEmpty();
            if (kbFallback)
            {
                // If SDL doesn't know a name, show fallback enclosed in brackets
                keyDisplay = QString(sdlkeys[j][1]) + QString(" ") + HWApplication::translate("binds (keys)", "(unsupported)");
            }
            if (isKeyboard)
            {
                if (!kbFallback)
                    keyDisplay = HWApplication::translate("binds (keys)", keyDisplay.toUtf8().constData());
                keyDisplay = HWApplication::translate("binds (keys)", "Keyboard") + QString(": ") + keyDisplay;
            }
            item->setData(keyDisplay, Qt::DisplayRole);
            item->setData(sdlkeys[j][0], Qt::UserRole + 1);
            m_bindsModel->appendRow(item);
        }
    }

    return m_bindsModel;
}

QString DataManager::settingsFileName()
{
    if(m_settingsFileName.isEmpty())
    {
        QFile settingsFile(cfgdir->absoluteFilePath("settings.ini"));

        if(!settingsFile.exists())
        {
            QFile oldSettingsFile(cfgdir->absoluteFilePath("hedgewars.ini"));

            settingsFile.open(QFile::WriteOnly);
            settingsFile.close();

            if(oldSettingsFile.exists())
            {
                QSettings sOld(oldSettingsFile.fileName(), QSettings::IniFormat);
                QSettings sNew(settingsFile.fileName(), QSettings::IniFormat);
                sNew.setIniCodec("UTF-8");

                foreach(const QString & key, sOld.allKeys())
                {
                    if(key.startsWith("colors/color"))
                        sNew.setValue(key, sOld.value(key).value<QColor>().name());
                    else
                        sNew.setValue(key, sOld.value(key));
                }
            }
        }

        m_settingsFileName = settingsFile.fileName();
    }

    return m_settingsFileName;
}

QString DataManager::safeFileName(QString fileName)
{
    fileName.replace('\\', '_');
    fileName.replace('/', '_');
    fileName.replace(':', '_');

    return fileName;
}

void DataManager::reload()
{
    // removed for now (also code was a bit unclean, could lead to segfault if
    // reload() is called before all members are initialized - because currently
    // they are initialized in the getter methods rather than the constructor)
}

void DataManager::resetColors()
{
    for(int i = colorsModel()->rowCount() - 1; i >= 0; --i)
    {
        m_colorsModel->item(i)->setData(QColor(colors[i]));
    }
}

bool DataManager::ensureFileExists(const QString &fileName)
{
    QFile tmpfile(fileName);
    if (!tmpfile.exists())
        return tmpfile.open(QFile::WriteOnly);
    else
        return true;
}
