/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2007-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QFileInfo>

#include "hwconsts.h"

#include "DataManager.h"


DataManager::DataManager()
{
    userData = new QDir(cfgdir->absolutePath());
    if (!userData->cd("Data"))
        userData = NULL;

    defaultData = new QDir(datadir->absolutePath());
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

    if (userData != NULL)
    {
        QDir tmpDir(*userData);
        if (tmpDir.cd(subDirectory))
            result.append(tmpDir.entryList(nameFilters, filters));
    }

    QDir tmpDir(*defaultData);
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

    if (userData != NULL)
        path = userData->absolutePath()+"/"+relativeDataFilePath;

    if ((!path.isEmpty()) && (!QFile::exists(path)))
        path = defaultData->absolutePath()+"/"+relativeDataFilePath;

    return path;
}


QString DataManager::findFileForWrite(
    const QString & relativeDataFilePath) const
{
    if (userData != NULL)
    {
        QString path = userData->absolutePath()+"/"+relativeDataFilePath;

        // create folders if needed
        QDir tmp;
        tmp.mkpath(QFileInfo(path).absolutePath());

        return path;
    }


    return "";
}

