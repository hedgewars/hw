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

#include <QDebug>
#include <QModelIndex>
#include "ammoSchemeModel.h"

AmmoSchemeModel::AmmoSchemeModel(QObject* parent) :
  QAbstractTableModel(parent)
{
	defaultScheme
		<< "Default" // name
		<< "false" // fortsmode
		<< "false" // team divide
		<< "false" // solid land
		<< "false" // border
		<< "45" // turn time
		<< "101" // init health
		<< "15" // sudden death
		<< "5" // case probability
		;

	schemes.append(defaultScheme);
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
		return defaultScheme.size();
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
	if (!index.isValid() || index.row() < 0
		|| index.row() >= schemes.size()
		|| index.column() >= defaultScheme.size()
		|| role != Qt::EditRole)
		return false;

	schemes[index.row()][index.column()] = value.toString();

	emit dataChanged(index, index);
	return true;
}

bool AmmoSchemeModel::insertRows(int row, int count, const QModelIndex & parent)
{
	beginInsertRows(parent, row, row);

	QStringList newScheme = defaultScheme;
	newScheme[0] = tr("new");
	
	schemes.insert(row, newScheme);

	endInsertRows();
}

bool AmmoSchemeModel::removeRows(int row, int count, const QModelIndex & parent)
{
	beginRemoveRows(parent, row, row);

	schemes.removeAt(row);

	endRemoveRows();
}

QVariant AmmoSchemeModel::data(const QModelIndex &index, int role) const
{
	if (!index.isValid() || index.row() < 0
		|| index.row() >= schemes.size()
		|| index.column() >= defaultScheme.size()
		|| (role != Qt::EditRole && role != Qt::DisplayRole)
		)
		return QVariant();

	return QVariant::fromValue(schemes[index.row()][index.column()]);
}
