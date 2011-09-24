/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2011 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QGroupBox>
#include <QLabel>
#include <QLineEdit>
#include <QSpinBox>

#include "pagenetserver.h"

PageNetServer::PageNetServer(QWidget* parent) : AbstractPage(parent)
{
    QFont * font14 = new QFont("MS Shell Dlg", 14);
    QGridLayout * pageLayout = new QGridLayout(this);
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 1);

    pageLayout->setRowStretch(0, 1);
    pageLayout->setRowStretch(1, 0);


    BtnBack =addButton(":/res/Exit.png", pageLayout, 1, 0, true);
    connect(BtnBack, SIGNAL(clicked()), this, SIGNAL(goBack()));


    BtnStart = new QPushButton(this);
    BtnStart->setFont(*font14);
    BtnStart->setText(QPushButton::tr("Start"));
    pageLayout->addWidget(BtnStart, 1, 2);

    QWidget * wg = new QWidget(this);
    pageLayout->addWidget(wg, 0, 0, 1, 3);

    QGridLayout * wgLayout = new QGridLayout(wg);
    wgLayout->setColumnStretch(0, 1);
    wgLayout->setColumnStretch(1, 3);
    wgLayout->setColumnStretch(2, 1);

    wgLayout->setRowStretch(0, 0);
    wgLayout->setRowStretch(1, 1);

    QGroupBox * gb = new QGroupBox(wg);
    wgLayout->addWidget(gb, 0, 1);

    QGridLayout * gbLayout = new QGridLayout(gb);

    labelSD = new QLabel(gb);
    labelSD->setText(QLabel::tr("Server name:"));
    gbLayout->addWidget(labelSD, 0, 0);

    leServerDescr = new QLineEdit(gb);
    gbLayout->addWidget(leServerDescr, 0, 1);

    labelPort = new QLabel(gb);
    labelPort->setText(QLabel::tr("Server port:"));
    gbLayout->addWidget(labelPort, 1, 0);

    sbPort = new QSpinBox(gb);
    sbPort->setMinimum(0);
    sbPort->setMaximum(65535);
    gbLayout->addWidget(sbPort, 1, 1);

    BtnDefault = new QPushButton(gb);
    BtnDefault->setText(QPushButton::tr("default"));
    gbLayout->addWidget(BtnDefault, 1, 2);

    connect(BtnDefault, SIGNAL(clicked()), this, SLOT(setDefaultPort()));
}

void PageNetServer::setDefaultPort()
{
    sbPort->setValue(46631);
}
