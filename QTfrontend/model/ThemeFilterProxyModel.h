/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2018 Andrey Korotaev <unC0Rr@gmail.com>
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
 * @brief Class definition of ThemeFilterProxyModel
 */

#ifndef HEDGEWARS_THEMEFILTERPROXYMODEL_H
#define HEDGEWARS_THEMEFILTERPROXYMODEL_H

#include <QSortFilterProxyModel>

/**
 * @brief A filter model for filtering DLC themes
 */
class ThemeFilterProxyModel : public QSortFilterProxyModel
{
        Q_OBJECT

    public:
        ThemeFilterProxyModel(QObject *parent = 0);
        void setFilterDLC(bool enabled);
        void setFilterHidden(bool enabled);
        void setFilterBackground(bool enabled);

    protected:
        bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

    private:
        bool isFilteringDLC;
        bool isFilteringHidden;
        bool isFilteringBackground;
};

#endif // HEDGEWARS_THEMEFILTERPROXYMODEL_H
