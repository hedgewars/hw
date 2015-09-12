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
 * @brief ThemeModel class implementation
 */

#include "physfs.h"
#include "ThemeModel.h"
#include "hwconsts.h"

ThemeModel::ThemeModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_data = QList<QMap<int, QVariant> >();

    m_themesLoaded = false;
}

int ThemeModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    else
    {
        if(!m_themesLoaded)
            loadThemes();
        return m_data.size();
    }
}


QVariant ThemeModel::data(const QModelIndex &index, int role) const
{
    if(index.column() > 0 || index.row() >= m_data.size())
        return QVariant();
    else
    {
        if(!m_themesLoaded)
            loadThemes();

        return m_data.at(index.row()).value(role);
    }
}


void ThemeModel::loadThemes() const
{
    qDebug("[LAZINESS] ThemeModel::loadThemes()");

    m_themesLoaded = true;


    DataManager & datamgr = DataManager::instance();

    QStringList themes =
        datamgr.entryList("Themes", QDir::AllDirs | QDir::NoDotAndDotDot);

    m_data.clear();

#if QT_VERSION >= QT_VERSION_CHECK(4, 7, 0)
    m_data.reserve(themes.size());
#endif

    foreach (QString theme, themes)
    {
        // themes without icon are supposed to be hidden
        QString iconpath = QString("physfs://Themes/%1/icon.png").arg(theme);

        if (!QFile::exists(iconpath))
            continue;

        QMap<int, QVariant> dataset;

        // detect if theme is dlc
        QString themeDir = PHYSFS_getRealDir(QString("Themes/%1/icon.png").arg(theme).toLocal8Bit().data());
        bool isDLC = !themeDir.startsWith(datadir->absolutePath());
        dataset.insert(IsDlcRole, isDLC);

        // set icon path
        dataset.insert(IconPathRole, iconpath);

        // set name
        dataset.insert(ActualNameRole, theme);

        // set displayed name
        dataset.insert(Qt::DisplayRole, (isDLC ? "*" : "") + theme);

        // load and set preview icon
        QIcon preview(QString("physfs://Themes/%1/icon@2x.png").arg(theme));
        dataset.insert(Qt::DecorationRole, preview);

        m_data.append(dataset);
    }
}
