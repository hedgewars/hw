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
 * @brief ThemeFilterProxyModel class implementation
 */

#include "ThemeModel.h"
#include "ThemeFilterProxyModel.h"

ThemeFilterProxyModel::ThemeFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    isFilteringDLC = false;
    isFilteringHidden = false;
    isFilteringBackground = false;
}

bool ThemeFilterProxyModel::filterAcceptsRow(int sourceRow, const QModelIndex & sourceParent) const
{
    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
    bool searchOkay = true;
    if(!filterRegExp().isEmpty())
    {
        // Check regular expression set by the theme chooser search
        QString name = index.data(ThemeModel::ActualNameRole).toString();
        int in = filterRegExp().indexIn(name);
        searchOkay = in != -1;
    }

    if(isFilteringDLC || isFilteringHidden || isFilteringBackground)
    {
        bool isDLC = index.data(ThemeModel::IsDlcRole).toBool();
        bool isHidden = index.data(ThemeModel::IsHiddenRole).toBool();
        bool isBackground = index.data(ThemeModel::IsBackgroundThemeRole).toBool();

        return ( ((isFilteringDLC && !isDLC) || !isFilteringDLC) &&
                 ((isFilteringHidden && !isHidden) || !isFilteringHidden) &&
                 ((isFilteringBackground && !isBackground) || !isFilteringBackground) ) &&
               searchOkay;
    }
    else
    {
        return searchOkay;
    }
}

void ThemeFilterProxyModel::setFilterDLC(bool enable)
{
    isFilteringDLC = enable;
    invalidateFilter();
}

void ThemeFilterProxyModel::setFilterHidden(bool enable)
{
    isFilteringHidden = enable;
    invalidateFilter();
}

void ThemeFilterProxyModel::setFilterBackground(bool enable)
{
    isFilteringBackground = enable;
    invalidateFilter();
};
