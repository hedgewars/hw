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
 * @brief ThemeModel class implementation
 */

#include "physfs.h"
#include "ThemeModel.h"

ThemeModel::ThemeModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_data = QList<QMap<int, QVariant> >();
}

int ThemeModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    else
        return m_data.size();
}


QVariant ThemeModel::data(const QModelIndex &index, int role) const
{
    if(index.column() > 0 || index.row() >= m_data.size())
        return QVariant();
    else
        return m_data.at(index.row()).value(role);
}


void ThemeModel::loadThemes()
{
    const QString appDir = QString(PHYSFS_getBaseDir());

    beginResetModel();

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
        dataset.insert(Qt::UserRole + 2, !themeDir.startsWith(appDir));

        // set icon path
        dataset.insert(Qt::UserRole + 1, iconpath);

        // set name
        dataset.insert(Qt::DisplayRole, theme);

        // load and set icon
        QIcon icon;
        icon.addPixmap(QPixmap(iconpath), QIcon::Normal);
        icon.addPixmap(QPixmap(iconpath), QIcon::Disabled);

        dataset.insert(Qt::DecorationRole, icon);

        // load and set preview icon
        QIcon preview(QString("physfs://Themes/%1/icon@2x.png").arg(theme));
        dataset.insert(Qt::UserRole, preview);

        m_data.append(dataset);
    }


    endResetModel();
}