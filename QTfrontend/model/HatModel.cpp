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
 * @brief HatModel class implementation
 */

#include "HatModel.h"

#include <QDir>
#include <QPixmap>
#include <QPainter>
#include "hwform.h" // player hash

#include "DataManager.h"

HatModel::HatModel(QObject* parent) :
    QAbstractListModel(parent)
{
    hats = QVector<QPair<QString, QIcon> >();
}

void HatModel::loadHats()
{
    // this method resets the contents of this model (important to know for views).
    beginResetModel();

    // prepare hats Vector
    hats.clear();

    DataManager & dataMgr = DataManager::instance();

    QPixmap hhpix = QPixmap(
                        dataMgr.findFileForRead("Graphics/Hedgehog/Idle.png")
                    ).copy(0, 0, 32, 32);

    // my reserved hats
    QStringList hatsList = dataMgr.entryList(
                               "Graphics/Hats/Reserved",
                               QDir::Files,
                               QStringList(playerHash+"*.png")
                           );

    int nReserved = hatsList.size();

    // regular hats
    hatsList.append(dataMgr.entryList(
                        "Graphics/Hats",
                        QDir::Files,
                        QStringList("*.png")
                    )
                   );


    int nHats = hatsList.size();

    for (int i = 0; i < nHats; i++)
    {
        bool isReserved = (i < nReserved);

        QString str = hatsList.at(i);
        str = str.remove(QRegExp("\\.png$"));
        QPixmap pix(
            dataMgr.findFileForRead(
                "Graphics/Hats/" + QString(isReserved?"Reserved/":"") + str +
                ".png"
            )
        );

        // rename properly
        if (isReserved)
            str = "Reserved "+str.remove(0,32);

        QPixmap tmppix(32, 37);
        tmppix.fill(QColor(Qt::transparent));

        QPainter painter(&tmppix);
        painter.drawPixmap(QPoint(0, 5), hhpix);
        painter.drawPixmap(QPoint(0, 0), pix.copy(0, 0, 32, 32));
        if(pix.width() > 32)
            painter.drawPixmap(QPoint(0, 0), pix.copy(32, 0, 32, 32));
        painter.end();

        if (str == "NoHat")
            hats.prepend(qMakePair(str, QIcon(tmppix)));
        else
            hats.append(qMakePair(str, QIcon(tmppix)));
    }


    endResetModel();
}

QVariant HatModel::headerData(int section,
                               Qt::Orientation orientation, int role) const
{
    Q_UNUSED(section);
    Q_UNUSED(orientation);
    Q_UNUSED(role);

    return QVariant();
}

int HatModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    else
        return hats.size();
}

/*int HatModel::columnCount(const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;
    else
        return 2;
}
*/
QVariant HatModel::data(const QModelIndex &index,
                         int role) const
{
    if (!index.isValid() || index.row() < 0
            || index.row() >= hats.size()
            || (role != Qt::DisplayRole && role != Qt::DecorationRole))
        return QVariant();

    if (role == Qt::DisplayRole)
        return hats.at(index.row()).first;
    else // role == Qt::DecorationRole
        return hats.at(index.row()).second;
}
