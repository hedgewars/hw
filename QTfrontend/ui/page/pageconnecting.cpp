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

#include <QVBoxLayout>
#include <QLabel>

#include "pageconnecting.h"

QLayout * PageConnecting::bodyLayoutDefinition()
{
    QVBoxLayout * pageLayout = new QVBoxLayout();

    QLabel * lblConnecting = new QLabel(this);
    lblConnecting->setText(tr("Connecting..."));
    pageLayout->addWidget(lblConnecting);

    return pageLayout;
}

void PageConnecting::connectSignals()
{
    connect(this, SIGNAL(goBack()), this, SIGNAL(cancelConnection()));
}

PageConnecting::PageConnecting(QWidget* parent) :  AbstractPage(parent)
{
    initPage();
}
