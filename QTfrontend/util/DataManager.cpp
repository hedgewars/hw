/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

/**
 * @file
 * @brief DataManager class implementation
 */

#include <QMap>
#include <QStringList>
#include <QStandardItemModel>
#include <QFileInfo>

#include "hwconsts.h"

#include "DataManager.h"

#include "GameStyleModel.h"
#include "HatModel.h"
#include "MapModel.h"
#include "ThemeModel.h"

DataManager::DataManager()
{
    m_userData = new QDir(cfgdir->absolutePath());
    if (!m_userData->cd("Data"))
        m_userData = NULL;

    m_defaultData = new QDir(datadir->absolutePath());

    m_hatModel = NULL;
    m_mapModel = NULL;
    m_themeModel = NULL;
    m_colorsModel = NULL;
}


DataManager & DataManager::instance()
{
    static DataManager instance;
    return instance;
}


QStringList DataManager::entryList(
    const QString & subDirectory,
    QDir::Filters filters,
    const QStringList & nameFilters
) const
{
    QStringList result;

    if (m_userData != NULL)
    {
        QDir tmpDir(*m_userData);
        if (tmpDir.cd(subDirectory))
            result.append(tmpDir.entryList(nameFilters, filters));
    }

    QDir tmpDir(*m_defaultData);
    if (tmpDir.cd(subDirectory))
        result.append(tmpDir.entryList(nameFilters, filters));

    result.removeDuplicates();

    // sort case-insensitive
    QMap<QString, QString> sortedFileNames;
    foreach ( QString fn, result)
    {
        sortedFileNames.insert(fn.toLower(), fn);
    }
    result = sortedFileNames.values();

    return result;
}


QString DataManager::findFileForRead(
    const QString & relativeDataFilePath) const
{
    QString path;

    if (m_userData != NULL)
        path = m_userData->absolutePath()+"/"+relativeDataFilePath;

    if ((!path.isEmpty()) && (!QFile::exists(path)))
        path = m_defaultData->absolutePath()+"/"+relativeDataFilePath;

    return path;
}


QString DataManager::findFileForWrite(
    const QString & relativeDataFilePath) const
{
    if (m_userData != NULL)
    {
        QString path = m_userData->absolutePath()+"/"+relativeDataFilePath;

        // create folders if needed
        QDir tmp;
        tmp.mkpath(QFileInfo(path).absolutePath());

        return path;
    }


    return "";
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

MapModel * DataManager::mapModel()
{
    if (m_mapModel == NULL) {
        m_mapModel = new MapModel();
        m_mapModel->loadMaps();
    }
    return m_mapModel;
}

ThemeModel * DataManager::themeModel()
{
    if (m_themeModel == NULL) {
        m_themeModel = new ThemeModel();
        m_themeModel->loadThemes();
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

void DataManager::reload()
{
    m_gameStyleModel->loadGameStyles();
    m_hatModel->loadHats();
    m_mapModel->loadMaps();
    m_themeModel->loadThemes();
    emit updated();
}
