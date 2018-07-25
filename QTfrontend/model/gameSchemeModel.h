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

#ifndef _GAME_SCHEME_MODEL_INCLUDED
#define _GAME_SCHEME_MODEL_INCLUDED

#include <QAbstractTableModel>
#include <QStringList>
#include <QList>

class GameSchemeModel : public QAbstractTableModel
{
        Q_OBJECT

    public:
        GameSchemeModel(QObject * parent, const QString & fileName);

        QVariant headerData(int section, Qt::Orientation orientation, int role) const;
        int rowCount(const QModelIndex & parent) const;
        int columnCount(const QModelIndex & parent) const;
        bool hasScheme(QString name);
        bool hasScheme(QString name, int ignoreID);
        bool renameScheme(int index, QString newName);
        Qt::ItemFlags flags(const QModelIndex & index) const;
        bool setData(const QModelIndex & index, const QVariant & value, int role = Qt::EditRole);
        bool insertRows(int row, int count, const QModelIndex & parent = QModelIndex());
        bool removeRows(int row, int count, const QModelIndex & parent = QModelIndex());
        QVariant data(const QModelIndex &index, int role) const;

        int numberOfDefaultSchemes;
        QStringList predefSchemesNames;
        QStringList spNames;

    public slots:
        void Save();

    signals:
        void dataChanged(const QModelIndex &topLeft, const QModelIndex& bottomRight);

    protected:
        QList< QList<QVariant> > schemes;
};

class NetGameSchemeModel : public QAbstractTableModel
{
        Q_OBJECT

    public:
        NetGameSchemeModel(QObject * parent);

        QVariant headerData(int section, Qt::Orientation orientation, int role) const;
        int rowCount(const QModelIndex & parent) const;
        int columnCount(const QModelIndex & parent) const;
        QVariant data(const QModelIndex &index, int role) const;

    public slots:
        void setNetSchemeConfig(QStringList cfg);

    private:
        QList<QVariant> netScheme;
};

#endif // _GAME_SCHEME_MODEL_INCLUDED
