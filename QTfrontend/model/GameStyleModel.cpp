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
 * @brief GameStyleModel class implementation
 */

#include <QTextStream>

#include "physfs.h"
#include "GameStyleModel.h"
#include "hwconsts.h"


void GameStyleModel::loadGameStyles()
{
    beginResetModel();

    QIcon dlcIcon;
    dlcIcon.addFile(":/res/dlcMarker.png", QSize(), QIcon::Normal, QIcon::On);
    QPixmap emptySpace = QPixmap(7, 15);
    emptySpace.fill(QColor(0, 0, 0, 0));
    QIcon notDlcIcon = QIcon(emptySpace);

    // empty list, so that we can (re)fill it
    QStandardItemModel::clear();

    QList<QStandardItem * > items;
    items.append(new QStandardItem(notDlcIcon, "Normal"));

    // define a separator item
    QStandardItem * separator = new QStandardItem("---");
    separator->setData(QLatin1String("separator"), Qt::AccessibleDescriptionRole);
    separator->setFlags(separator->flags() & ~( Qt::ItemIsEnabled | Qt::ItemIsSelectable ) );

    items.append(separator);


    QStringList scripts = DataManager::instance().entryList(
                             QString("Scripts/Multiplayer"),
                             QDir::Files,
                             QStringList("*.lua")
                         );

    foreach(QString script, scripts)
    {
        script = script.remove(".lua", Qt::CaseInsensitive);

        QFile scriptCfgFile(QString("physfs://Scripts/Multiplayer/%2.cfg").arg(script));

        QString name = script;
        name = name.replace("_", " ");

        QString scheme = "locked";
        QString weapons = "locked";

        if (scriptCfgFile.exists() && scriptCfgFile.open(QFile::ReadOnly))
        {
            QTextStream input(&scriptCfgFile);
            input >> scheme;
            input >> weapons;
            scriptCfgFile.close();

            if (!scheme.isEmpty())
                scheme.replace("_", " ");

            if (!weapons.isEmpty())
                weapons.replace("_", " ");
        }

        // detect if script is dlc
        QString scriptPath = PHYSFS_getRealDir(QString("Scripts/Multiplayer/%1.lua").arg(script).toLocal8Bit().data());
        bool isDLC = !scriptPath.startsWith(datadir->absolutePath());

        QStandardItem * item;
        if (isDLC)
            item = new QStandardItem(dlcIcon, name);
        else
            item = new QStandardItem(notDlcIcon, name);

        item->setData(script, ScriptRole);
        item->setData(scheme, SchemeRole);
        item->setData(weapons, WeaponsRole);
        item->setData(isDLC, IsDlcRole);

        items.append(item);
    }

    QStandardItemModel::appendColumn(items);


    endResetModel();
}




