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
 * @brief HatModel class implementation
 */

#include "HatModel.h"

#include <QDir>
#include <QPixmap>
#include <QPainter>
#include <QList>
#include "hwform.h" // player hash

#include "DataManager.h"

HatModel::HatModel(QObject* parent) :
    QStandardItemModel(parent)
{}

void HatModel::loadHats()
{
    qDebug("HatModel::loadHats()");

    // this method resets the contents of this model (important to know for views).
    QStandardItemModel::beginResetModel();
    QStandardItemModel::clear();

    // New hats to add to model
    QList<QStandardItem *> hats;

    // we'll need the DataManager a few times, so let's get a reference to it
    DataManager & dataMgr = DataManager::instance();

    // Default hat icon
    QPixmap hhpix = QPixmap("physfs://Graphics/Hedgehog/Idle.png").copy(0, 0, 32, 32);

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

    // Add each hat
    for (int i = 0; i < nHats; i++)
    {
        bool isReserved = (i < nReserved);

        if (isReserved) continue; // For some reason, reserved hats were added in 9.19-dev, so this will hide them. Uncomment to show them.

        QString str = hatsList.at(i);
        str = str.remove(QRegExp("\\.png$"));
        QPixmap hatpix(
                "physfs://Graphics/Hats/" + QString(isReserved?"Reserved/":"") + str +
                ".png"
        );

        // rename properly
        if (isReserved)
            str = "Reserved "+str.remove(0,32);

        // Color for team hats. We use the default color of the first team.
        QColor overlay_color = QColor(colors[0]);

        QPixmap ppix(32, 37);
        ppix.fill(QColor(Qt::transparent));
        QPainter painter(&ppix);

        QPixmap opix(32, 37);
        opix.fill(QColor(Qt::transparent));
        QPainter overlay_painter(&opix);

        // The hat is drawn in reverse: First the color overlay, then the hat, then the hedgehog.

        // draw hat's color layer, if present
        int overlay_offset = -1;
        if((hatpix.height() == 32) && (hatpix.width() == 64)) {
            overlay_offset = 32;
        } else if(hatpix.width() > 64) {
            overlay_offset = 64;
        }
        if(overlay_offset > -1) {
            // colorized layer
            overlay_painter.drawPixmap(QPoint(0, 0), hatpix.copy(overlay_offset, 0, 32, 32));
            overlay_painter.setCompositionMode(QPainter::CompositionMode_Multiply);
            overlay_painter.fillRect(0, 0, 32, 32, overlay_color);

            // uncolorized layer and combine
            painter.drawPixmap(QPoint(0, 0), hatpix.copy(overlay_offset, 0, 32, 32));
            painter.setCompositionMode(QPainter::CompositionMode_SourceAtop);
            painter.drawPixmap(QPoint(0, 0), opix.copy(0, 0, 32, 32));
        }

        // draw hat below the color layer
        painter.setCompositionMode(QPainter::CompositionMode_DestinationOver);
        painter.drawPixmap(QPoint(0, 0), hatpix.copy(0, 0, 32, 32));

        // draw hedgehog below the hat
        painter.drawPixmap(QPoint(0, 5), hhpix);

        painter.end();

        if (str == "NoHat")
            hats.prepend(new QStandardItem(QIcon(ppix), str));
        else
            hats.append(new QStandardItem(QIcon(ppix), str));
    }

    QStandardItemModel::appendColumn(hats);
    QStandardItemModel::endResetModel();
}
