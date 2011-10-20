/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2007-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QMap>
#include <QStringList>

#include "hwconsts.h"

#include "HWDataManager.h"


HWDataManager::HWDataManager()
{
    userData = new QDir(cfgdir->absolutePath());
    if (!userData->cd("Data"))
        userData = NULL;

    defaultData = new QDir(datadir->absolutePath());
}


HWDataManager & HWDataManager::instance()
{
    static HWDataManager instance;
    return instance;
}


QStringList HWDataManager::entryList(
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


QFile * HWDataManager::findFileForRead(
                                const QString & relativeDataFilePath) const
{
    QFile * file =
            new QFile(userData->absolutePath()+"/"+relativeDataFilePath);
    if (!file->exists())
    {
        delete file;
        file = new QFile(defaultData->absolutePath()+"/"+relativeDataFilePath);
    }
    return file;
}


QFile * HWDataManager::findFileForWrite(
                                const QString & relativeDataFilePath) const
{
    return new QFile(userData->absolutePath()+"/"+relativeDataFilePath);
}

