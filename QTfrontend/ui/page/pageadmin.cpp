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
#include <QLabel>
#include <QLineEdit>
#include <QSpinBox>
#include <QPushButton>
#include <QTextBrowser>

#include "pageadmin.h"
#include "chatwidget.h"

QLayout * PageAdmin::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    // 0
    pbAsk = addButton(tr("Fetch data"), pageLayout, 0, 0, 1, 3);

    // 1
    QLabel * lblSMN = new QLabel(this);
    lblSMN->setText(tr("Server message for latest version:"));
    pageLayout->addWidget(lblSMN, 1, 0);

    leServerMessageNew = new QLineEdit(this);
    pageLayout->addWidget(leServerMessageNew, 1, 1);

    // 2
    QLabel * lblSMO = new QLabel(this);
    lblSMO->setText(tr("Server message for previous versions:"));
    pageLayout->addWidget(lblSMO, 2, 0);

    leServerMessageOld = new QLineEdit(this);
    pageLayout->addWidget(leServerMessageOld, 2, 1);

    // 3
    QLabel * lblP = new QLabel(this);
    lblP->setText(tr("Latest version protocol number:"));
    pageLayout->addWidget(lblP, 3, 0);

    sbProtocol = new QSpinBox(this);
    pageLayout->addWidget(sbProtocol, 3, 1);

    // 4
    QLabel * lblPreview = new QLabel(this);
    lblPreview->setText(tr("MOTD preview:"));
    pageLayout->addWidget(lblPreview, 4, 0);

    tb = new QTextBrowser(this);
    tb->setOpenExternalLinks(true);
    tb->document()->setDefaultStyleSheet(HWChatWidget::styleSheet());
    pageLayout->addWidget(tb, 4, 1, 1, 2);

    // 5
    pbClearAccountsCache = addButton(tr("Clear Accounts Cache"), pageLayout, 5, 0);

    // 6
    pbSetSM = addButton(tr("Set data"), pageLayout, 6, 0, 1, 3);

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
