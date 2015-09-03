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
         * @brief Returns pointer to a model of available static maps.
         *
         * The model is updated automatically on data reload.
         *
         * @return map model pointer.
         */
        MapModel * staticMapModel();

        /**
         * @brief Returns pointer to a model of available mission maps.
         *
         * The model is updated automatically on data reload.
         *
         * @return map model pointer.
         */
        MapModel * missionMapModel();

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

        QString settingsFileName();

        static QString safeFileName(QString fileName);

        static bool ensureFileExists(const QString & fileName);

    public slots:
        /// Reloads data from storage.
        void reload();
        void resetColors();


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

        GameStyleModel * m_gameStyleModel; ///< game style model instance
        HatModel * m_hatModel; ///< hat model instance
        MapModel * m_staticMapModel; ///< static map model instance
        MapModel * m_missionMapModel; ///< mission map model instance
        ThemeModel * m_themeModel; ///< theme model instance
        QStandardItemModel * m_colorsModel;
        QStandardItemModel * m_bindsModel;
        QString m_settingsFileName;
};

#endif // HEDGEWARS_DATAMANAGER_H
