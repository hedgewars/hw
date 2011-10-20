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

#ifndef HEDGEWARS_HWDATAMANAGER_H
#define HEDGEWARS_HWDATAMANAGER_H

#include <QDir>
#include <QFile>

#include <QStringList>

class QDir;
class QFile;
class QStringList;

/**
 * Offers access to the data files of hedgewars.
 * Note: singleton pattern
 * @author sheepluva
 * @since 0.9.17
 */
class HWDataManager
{
public:
    /**
     * Returns a pointer to the singleton instance of this class.
     * @return pointer to the instance.
     */
    static HWDataManager & instance();

    /**
     * Returns a pointer to the singleton instance of this class.
     * @param subDirectory sub-directory to search.
     * @param filters filters for entry type.
     * @param namefilters filters by name patterns.
     * @return a list of matches in the subDirectory of data directory.
     */
    QStringList entryList(const QString & subDirectory,
                          QDir::Filters filters = QDir::NoFilter,
                          const QStringList & nameFilters = QStringList()
                         ) const;

    /**
     * Creates a QFile for the desired data path and returns a pointer to it.
     * Use this method if you want to read an existing data file;
     * @param relativeDataFilePath path to the data file.
     * @return respective QFile pointer, the actual file may actually not exist.
     */
    QFile * findFileForRead(const QString & relativeDataFilePath) const;


    /**
     * Creates a QFile for the desired data path and returns a pointer to it.
     * Use this method if you want to create or write into a data file.
     * @param relativeDataFilePath path to the data file.
     * @return respective QFile pointer.
     */
    QFile * findFileForWrite(const QString & relativeDataFilePath) const;


private:
    /**
     * Singleton class constructor.
     */
    HWDataManager();

    QDir * defaultData;
    QDir * userData;
};

#endif // HEDGEWARS_HWDATAMANAGER_H
