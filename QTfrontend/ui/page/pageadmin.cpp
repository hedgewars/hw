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
#include <QLabel>
#include <QLineEdit>
#include <QSpinBox>
#include <QPushButton>
#include <QTextBrowser>
#include <QTableWidget>
#include <QHeaderView>

#include "pageadmin.h"
#include "chatwidget.h"
#include "bandialog.h"

QLayout * PageAdmin::bodyLayoutDefinition()
{
    QVBoxLayout * pageLayout = new QVBoxLayout();

    QTabWidget * tabs = new QTabWidget(this);
    pageLayout->addWidget(tabs);
    QWidget * page1 = new QWidget(this);
    QWidget * page2 = new QWidget(this);
    tabs->addTab(page1, tr("General"));
    tabs->addTab(page2, tr("Bans"));

    // page 1
    {
        QGridLayout * tab1Layout = new QGridLayout(page1);

        // 0
        pbAsk = addButton(tr("Fetch data"), tab1Layout, 0, 0, 1, 3);

        // 1
        QLabel * lblSMN = new QLabel(this);
        lblSMN->setText(tr("Server message for latest version:"));
        tab1Layout->addWidget(lblSMN, 1, 0);

        leServerMessageNew = new QLineEdit(this);
        tab1Layout->addWidget(leServerMessageNew, 1, 1);

        // 2
        QLabel * lblSMO = new QLabel(this);
        lblSMO->setText(tr("Server message for previous versions:"));
        tab1Layout->addWidget(lblSMO, 2, 0);

        leServerMessageOld = new QLineEdit(this);
        tab1Layout->addWidget(leServerMessageOld, 2, 1);

        // 3
        QLabel * lblP = new QLabel(this);
        lblP->setText(tr("Latest version protocol number:"));
        tab1Layout->addWidget(lblP, 3, 0);

        sbProtocol = new QSpinBox(this);
        tab1Layout->addWidget(sbProtocol, 3, 1);

        // 4
        QLabel * lblPreview = new QLabel(this);
        lblPreview->setText(tr("MOTD preview:"));
        tab1Layout->addWidget(lblPreview, 4, 0);

        tb = new QTextBrowser(this);
        tb->setOpenExternalLinks(true);
        tb->document()->setDefaultStyleSheet(HWChatWidget::styleSheet());
        tab1Layout->addWidget(tb, 4, 1, 1, 2);

        // 5
        pbClearAccountsCache = addButton(tr("Clear Accounts Cache"), tab1Layout, 5, 0);

        // 6
        pbSetSM = addButton(tr("Set data"), tab1Layout, 6, 0, 1, 3);
    }

    // page 2
    {
        QGridLayout * tab2Layout = new QGridLayout(page2);
        twBans = new QTableWidget(this);
        twBans->setColumnCount(3);
        twBans->setHorizontalHeaderLabels(QStringList()
                              << tr("IP/Nick")
                              << tr("Expiration")
                              << tr("Reason")
                    );
        twBans->horizontalHeader()->setSectionResizeMode(2, QHeaderView::Stretch);
        twBans->setEditTriggers(QAbstractItemView::NoEditTriggers);
        twBans->setSelectionBehavior(QAbstractItemView::SelectRows);
        twBans->setSelectionMode(QAbstractItemView::SingleSelection);
        twBans->setAlternatingRowColors(true);
        tab2Layout->addWidget(twBans, 0, 1, 4, 1);

        QPushButton * btnRefresh = addButton(tr("Refresh"), tab2Layout, 0, 0);
        QPushButton * btnAdd = addButton(tr("Add"), tab2Layout, 1, 0);
        QPushButton * btnRemove = addButton(tr("Remove"), tab2Layout, 2, 0);

        connect(btnRefresh, SIGNAL(clicked()), this, SIGNAL(bansListRequest()));
        connect(btnRefresh, SIGNAL(clicked()), this, SLOT(onRefreshClicked()));
        connect(btnAdd, SIGNAL(clicked()), this, SLOT(onAddClicked()));
        connect(btnRemove, SIGNAL(clicked()), this, SLOT(onRemoveClicked()));
    }

    return pageLayout;
}

void PageAdmin::connectSignals()
{
    connect(pbAsk, SIGNAL(clicked()), this, SIGNAL(askServerVars()));
    connect(leServerMessageNew, SIGNAL(textChanged(QString)), tb, SLOT(setHtml(const QString &)));
    connect(leServerMessageOld, SIGNAL(textChanged(QString)), tb, SLOT(setHtml(const QString &)));
    connect(pbClearAccountsCache, SIGNAL(clicked()), this, SIGNAL(clearAccountsCache()));
    connect(pbSetSM, SIGNAL(clicked()), this, SLOT(smChanged()));
}

PageAdmin::PageAdmin(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}

void PageAdmin::smChanged()
{
    emit setServerMessageNew(leServerMessageNew->text());
    emit setServerMessageOld(leServerMessageOld->text());
    emit setProtocol(sbProtocol->value());
}

void PageAdmin::serverMessageNew(const QString & str)
{
    leServerMessageNew->setText(str);
}

void PageAdmin::serverMessageOld(const QString & str)
{
    leServerMessageOld->setText(str);
}

void PageAdmin::protocol(int proto)
{
    sbProtocol->setValue(proto);
}

void PageAdmin::onAddClicked()
{
    BanDialog dialog(this);

    if(dialog.exec())
    {
        if(dialog.byIP())
        {
            emit banIP(dialog.banId(), dialog.reason(), dialog.duration());
        } else
        {
            emit banNick(dialog.banId(), dialog.reason(), dialog.duration());
        }

        emit bansListRequest();
    }
}

void PageAdmin::onRemoveClicked()
{
    QList<QTableWidgetItem *> sel = twBans->selectedItems();

    if(sel.size())
    {
        emit removeBan(twBans->item(sel[0]->row(), 0)->data(Qt::DisplayRole).toString());
        emit bansListRequest();
    }
}

void PageAdmin::setBansList(const QStringList & bans)
{
    if(bans.size() % 4)
        return;

    twBans->setRowCount(bans.size() / 4);

    for(int i = 0; i < bans.size(); i += 4)
    {
        if(!twBans->item(i / 4, 0))
        {
            twBans->setItem(i / 4, 0, new QTableWidgetItem());
            twBans->setItem(i / 4, 1, new QTableWidgetItem());
            twBans->setItem(i / 4, 2, new QTableWidgetItem());
        }

        twBans->item(i / 4, 0)->setData(Qt::DisplayRole, bans[i + 1]);
        twBans->item(i / 4, 1)->setData(Qt::DisplayRole, bans[i + 3]);
        twBans->item(i / 4, 2)->setData(Qt::DisplayRole, bans[i + 2]);
    }
}

void PageAdmin::onRefreshClicked()
{
    twBans->setRowCount(0);
}
