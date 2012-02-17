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
 * @brief HWDataManager class definition
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
 * @brief Offers access to the data files of hedgewars.
 *
 * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
 *
 * @author sheepluva
 * @since 0.9.17
 */
class HWDataManager
{
    public:
        /**
         * @brief Returns reference to the <i>singleton</i> instance of this class.
         *
         * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
         *
         * @return reference to the instance.
         */
        static HWDataManager & instance();

        /**
         * @brief Returns a sorted list of data directory entries.
         *
         * @param subDirectory sub-directory to search.
         * @param filters filters for entry type.
         * @param nameFilters filters by name patterns.
         * @return a sorted list of matches in the subDirectory of data directory.
         */
        QStringList entryList(const QString & subDirectory,
                              QDir::Filters filters = QDir::NoFilter,
                              const QStringList & nameFilters = QStringList("*")
                             ) const;

        /**
         * @brief Returns the path for the desires data file.
         *
         * Use this method if you want to read an existing data file.
         *
         * @param relativeDataFilePath relative path of the data file.
         * @return real path to the file.
         */
        QString findFileForRead(const QString & relativeDataFilePath) const;


        /**
         * @brief Returns the path for the data file that is to be written.
         *
         * Use this method if you want to create or write into a data file.
         *
         * @param relativeDataFilePath relative path of data file write path.
         * @return destination of path data file.
         */
        QString findFileForWrite(const QString & relativeDataFilePath) const;


    private:
        /**
         * @brief Class constructor of the <i>singleton</i>.
         *
         * Not to be used from outside the class,
         * use the static {@link HWDataManager::instance()} instead.
         *
         * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
         */
        HWDataManager();

        QDir * defaultData; ///< directory of the installed data
        QDir * userData;    ///< directory of custom data in the user's directory
};

#endif // HEDGEWARS_HWDATAMANAGER_H
