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

#include <QLineEdit>
#include <QSpinBox>
#include <QPushButton>
#include <QGridLayout>
#include <QLabel>

#include "input_ip.h"
#include "hwconsts.h"

HWHostPortDialog::HWHostPortDialog(QWidget* parent) : QDialog(parent)
{
    QGridLayout * layout = new QGridLayout(this);

    QLabel * lbHost = new QLabel(this);
    lbHost->setText(QLabel::tr("Host:"));
    layout->addWidget(lbHost, 0, 0);

    QLabel * lbPort = new QLabel(this);
    lbPort->setText(QLabel::tr("Port:"));
    layout->addWidget(lbPort, 1, 0);

    leHost = new QLineEdit(this);
    layout->addWidget(leHost, 0, 1, 1, 2);

    sbPort = new QSpinBox(this);
    sbPort->setMinimum(0);
    sbPort->setMaximum(65535);
    layout->addWidget(sbPort, 1, 1, 1, 2);

    pbDefault = new QPushButton(this);
    pbDefault->setText(QPushButton::tr("default"));
    layout->addWidget(pbDefault, 1, 3);

    pbOK = new QPushButton(this);
    pbOK->setText(QPushButton::tr("OK"));
    pbOK->setDefault(true);
    layout->addWidget(pbOK, 3, 1);

    pbCancel = new QPushButton(this);
    pbCancel->setText(QPushButton::tr("Cancel"));
    layout->addWidget(pbCancel, 3, 2);

    connect(pbOK, SIGNAL(clicked()), this, SLOT(accept()));
    connect(pbCancel, SIGNAL(clicked()), this, SLOT(reject()));
    connect(pbDefault, SIGNAL(clicked()), this, SLOT(setDefaultPort()));

    this->setWindowModality(Qt::WindowModal);
    this->setWindowTitle(tr("Connect to server"));
}

void HWHostPortDialog::setDefaultPort()
{
    sbPort->setValue(NETGAME_DEFAULT_PORT);
}
