/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QModelIndex>
#include "ammoSchemeModel.h"

AmmoSchemeModel::AmmoSchemeModel(QObject* parent) :
  QAbstractTableModel(parent)
{

}

QVariant AmmoSchemeModel::headerData(int section, Qt::Orientation orientation, int role) const
{
	return QVariant();
}

int AmmoSchemeModel::rowCount(const QModelIndex &parent) const
{
	if (parent.isValid())
		return 0;
	else
		return schemes.size();
}

int AmmoSchemeModel::columnCount(const QModelIndex & parent) const
{
	if (parent.isValid())
		return 0;
	else
		return 3;
}

Qt::ItemFlags AmmoSchemeModel::flags(const QModelIndex & index) const
{
	return
		Qt::ItemIsEnabled
		| Qt::ItemIsSelectable
		| Qt::ItemIsEditable;
}

bool AmmoSchemeModel::setData(const QModelIndex & index, const QVariant & value, int role)
{
	emit dataChanged(index, index);
}
