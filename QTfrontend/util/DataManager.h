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
 * @brief DataManager class definition
 */

#ifndef HEDGEWARS_DATAMANAGER_H
#define HEDGEWARS_DATAMANAGER_H

#include <QDir>
#include <QFile>
#include <QStringList>

class GameStyleModel;
class HatModel;
class MapModel;
class ThemeModel;
class QStandardItemModel;

/**
 * @brief Offers access to the data files of hedgewars.
 *
 * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
 *
 * @author sheepluva
 * @since 0.9.17
 */
class DataManager: public QObject
{
        Q_OBJECT

    public:
        /**
         * @brief Returns reference to the <i>singleton</i> instance of this class.
         *
         * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
         *
         * @return reference to the instance.
         */
        static DataManager & instance();

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


        /**
         * @brief Returns pointer to a model of available game styles.
         *
         * The model is updated automatically on data reload.
         *
         * @return game style model pointer.
         */
        GameStyleModel * gameStyleModel();

        /**
         * @brief Returns pointer to a model of available hats.
         *
         * The model is updated automatically on data reload.
         *
         * @return hat model pointer.
         */
        HatModel * hatModel();

        /**
         * @brief Returns pointer to a model of available maps.
         *
         * The model is updated automatically on data reload.
         *
         * @return map model pointer.
         */
        MapModel * mapModel();

        /**
         * @brief Returns pointer to a model of available themes.
         *
         * The model is updated automatically on data reload.
         *
         * @return theme model pointer.
         */
        ThemeModel * themeModel();

        QStandardItemModel * colorsModel();
        QStandardItemModel * bindsModel();

    public slots:
        /// Reloads data from storage.
        void reload();


    signals:
        /// This signal is emitted after the data has been updated.
        void updated();


    private:
        /**
         * @brief Class constructor of the <i>singleton</i>.
         *
         * Not to be used from outside the class,
         * use the static {@link DataManager::instance()} instead.
         *
         * @see <a href="http://en.wikipedia.org/wiki/Singleton_pattern">singleton pattern</a>
         */
        DataManager();

        QDir * m_defaultData; ///< directory of the installed data
        QDir * m_userData;    ///< directory of custom data in the user's directory

        GameStyleModel * m_gameStyleModel; ///< game style model instance
        HatModel * m_hatModel; ///< hat model instance
        MapModel * m_mapModel; ///< map model instance
        ThemeModel * m_themeModel; ///< theme model instance
        QStandardItemModel * m_colorsModel;
        QStandardItemModel * m_bindsModel;
};

#endif // HEDGEWARS_DATAMANAGER_H
