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
#include <QPushButton>
#include <QGroupBox>
#include <QTableView>
#include <QMessageBox>
#include <QHeaderView>

#include "pagenet.h"
#include "hwconsts.h"
#include "netudpwidget.h"

QLayout * PageNet::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 1);

    ConnGroupBox = new QGroupBox(this);
    ConnGroupBox->setTitle(QGroupBox::tr("Net game"));
    pageLayout->addWidget(ConnGroupBox, 2, 0, 1, 3);
    GBClayout = new QGridLayout(ConnGroupBox);
    GBClayout->setColumnStretch(0, 1);
    GBClayout->setColumnStretch(1, 1);
    GBClayout->setColumnStretch(2, 1);

    BtnNetConnect = new QPushButton(ConnGroupBox);
    BtnNetConnect->setFont(*font14);
    BtnNetConnect->setText(QPushButton::tr("Connect"));
    BtnNetConnect->setWhatsThis(tr("Connect to the selected server"));
    GBClayout->addWidget(BtnNetConnect, 2, 2);

    tvServersList = new QTableView(ConnGroupBox);
    tvServersList->setSelectionBehavior(QAbstractItemView::SelectRows);
    GBClayout->addWidget(tvServersList, 1, 0, 1, 3);

    BtnUpdateSList = new QPushButton(ConnGroupBox);
    BtnUpdateSList->setFont(*font14);
    BtnUpdateSList->setText(QPushButton::tr("Update"));
    BtnUpdateSList->setWhatsThis(tr("Update the list of servers"));
    GBClayout->addWidget(BtnUpdateSList, 2, 0);

    BtnSpecifyServer = new QPushButton(ConnGroupBox);
    BtnSpecifyServer->setFont(*font14);
    BtnSpecifyServer->setText(QPushButton::tr("Specify address"));
    BtnSpecifyServer->setWhatsThis(tr("Specify the address and port number of a known server and connect to it directly"));
    GBClayout->addWidget(BtnSpecifyServer, 2, 1);

    return pageLayout;
}

QLayout * PageNet::footerLayoutDefinition()
{
    QHBoxLayout * footerLayout = new QHBoxLayout();

    BtnNetSvrStart = formattedButton(QPushButton::tr("Start server"));
    BtnNetSvrStart->setWhatsThis(tr("Start private server"));
    BtnNetSvrStart->setMinimumSize(180, 50);
    QString serverPath = bindir->absolutePath() + "/hedgewars-server";
#ifdef Q_OS_WIN
    serverPath += + ".exe";
#endif
    QFile server(serverPath);
    BtnNetSvrStart->setVisible(server.exists());

    footerLayout->addStretch();
    footerLayout->addWidget(BtnNetSvrStart, 0, Qt::AlignBottom);

    return footerLayout;
}

void PageNet::connectSignals()
{
    connect(BtnNetConnect, SIGNAL(clicked()), this, SLOT(slotConnect()));
}

PageNet::PageNet(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}

void PageNet::updateServersList()
{
    tvServersList->setModel(new HWNetUdpModel(tvServersList));

    tvServersList->horizontalHeader()->setSectionResizeMode(0, QHeaderView::Stretch);

    static_cast<HWNetServersModel *>(tvServersList->model())->updateList();

    connect(BtnUpdateSList, SIGNAL(clicked()), static_cast<HWNetServersModel *>(tvServersList->model()), SLOT(updateList()));
    connect(tvServersList, SIGNAL(doubleClicked(const QModelIndex &)), this, SLOT(slotConnect()));
}

void PageNet::slotConnect()
{
    HWNetServersModel * model = static_cast<HWNetServersModel *>(tvServersList->model());
    QModelIndex mi = tvServersList->currentIndex();
    if(!mi.isValid())
    {
        QMessageBox serverMsg(this);
        serverMsg.setIcon(QMessageBox::Warning);
        serverMsg.setWindowTitle(QMessageBox::tr("Netgame - Error"));
        serverMsg.setText(QMessageBox::tr("Please select a server from the list"));
        serverMsg.setWindowModality(Qt::WindowModal);
        serverMsg.exec();
        return;
    }
    QString host = model->index(mi.row(), 1).data().toString();
    quint16 port = model->index(mi.row(), 2).data().toUInt();

    emit connectClicked(host, port, false);
}
