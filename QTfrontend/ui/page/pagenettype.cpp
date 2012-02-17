/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QGridLayout>
#include <QPushButton>

#include "pagenettype.h"


QLayout * PageNetType::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();
    pageLayout->setRowStretch(0, 10);
    pageLayout->setRowStretch(3, 10);

    pageLayout->setColumnStretch(1, 10);
    pageLayout->setColumnStretch(2, 20);
    pageLayout->setColumnStretch(3, 10);

    BtnLAN = addButton(tr("LAN game"), pageLayout, 1, 2);
    BtnLAN->setWhatsThis(tr("Hoin or host your own game server in a Local Area Network."));
    BtnOfficialServer = addButton(tr("Official server"), pageLayout, 2, 2);
    BtnOfficialServer->setWhatsThis(tr("Join hundreds of players online!"));

    // hack: temporary deactivated - requires server modifications that aren't backward compatible (yet)
    //BtnOfficialServer->setEnabled(false);

    return pageLayout;
}

PageNetType::PageNetType(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}
