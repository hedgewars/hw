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

#include <QGridLayout>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QPushButton>
#include <QGroupBox>
#include <QLabel>
#include <QLineEdit>
#include <QSpinBox>
#include <QTcpSocket>
#include <QHostAddress>
#include <QClipboard>

#include "pagenetserver.h"
#include "hwconsts.h"
#include "HWApplication.h"

QLayout * PageNetServer::bodyLayoutDefinition()
{
    QVBoxLayout * pageLayout = new QVBoxLayout();

    QWidget * wg = new QWidget(this);
    pageLayout->addWidget(wg);

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
    sbPort->setMinimum(1024);
    sbPort->setMaximum(65535);
    gbLayout->addWidget(sbPort, 1, 1);

    BtnDefault = new QPushButton(gb);
    BtnDefault->setMinimumWidth(50);
    BtnDefault->setText(QPushButton::tr("Reset"));
    BtnDefault->setWhatsThis(QPushButton::tr("Set the default server port for Hedgewars"));
    gbLayout->addWidget(BtnDefault, 1, 2);

    BtnShare = new QPushButton(gb);
    BtnShare->setText(QPushButton::tr("Invite your friends to your server in just 1 click!"));
    BtnShare->setWhatsThis(QPushButton::tr("Click to copy your unique server URL to your clipboard. Send this link to your friends and they will be able to join you."));
    gbLayout->addWidget(BtnShare, 2, 1);

    labelURL = new QLabel(gb);
    labelURL->setText(
              "<style type=\"text/css\"> a { color: #ffcc00; } </style>"
              "<div align=\"center\">"
              "<a href=\"hedgewars.org/kb/HWPlaySchemeSyntax\">" +
              tr("Click here for details") +
              "</a></div>");
    labelURL->setOpenExternalLinks(true);
    gbLayout->addWidget(labelURL, 3, 1);

    return pageLayout;
}

QLayout * PageNetServer::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    BtnStart = formattedButton(QPushButton::tr("Start"));
    BtnStart->setWhatsThis(QPushButton::tr("Start private server"));
    BtnStart->setMinimumWidth(180);

    bottomLayout->addStretch();
    bottomLayout->addWidget(BtnStart);

    return bottomLayout;
}

void PageNetServer::connectSignals()
{
    connect(BtnDefault, SIGNAL(clicked()), this, SLOT(setDefaultPort()));
    connect(BtnShare, SIGNAL(clicked()), this, SLOT(copyUrl()));
}

PageNetServer::PageNetServer(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}

void PageNetServer::setDefaultPort()
{
    sbPort->setValue(NETGAME_DEFAULT_PORT);
}

// This function assumes that the user wants to share his server while connected to
// the Internet and that he/she is using direct access (eg no NATs). To determine the
// IP we briefly connect to Hedgewars website and fallback to user intervention
// after 4 seconds of timeout.
void PageNetServer::copyUrl()
{
    QString address = "hwplay://";

    QTcpSocket socket;
    socket.connectToHost("www.hedgewars.org", 80);
    if (socket.waitForConnected(4000))
        address += socket.localAddress().toString();
    else
        address += "<" + tr("Insert your address here") + ">";

    if (sbPort->value() != NETGAME_DEFAULT_PORT)
        address += ":" + QString::number(sbPort->value());

    QClipboard *clipboard = HWApplication::clipboard();
    clipboard->setText(address);
    qDebug() << address << "copied to clipboard";
}

