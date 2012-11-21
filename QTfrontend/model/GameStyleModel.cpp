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
 * @brief GameStyleModel class implementation
 */

#include <QTextStream>

#include "GameStyleModel.h"


void GameStyleModel::loadGameStyles()
{
    beginResetModel();


    // empty list, so that we can (re)fill it
    QStandardItemModel::clear();

    QList<QStandardItem * > items;
    items.append(new QStandardItem("Normal"));

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

        QStandardItem * item = new QStandardItem(name);

        item->setData(script, ScriptRole);
        item->setData(scheme, SchemeRole);
        item->setData(weapons, WeaponsRole);

        items.append(item);
    }

    QStandardItemModel::appendColumn(items);


    endResetModel();
}




