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
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QFileInfo>
#include <QFileDialog>

#include "pagedata.h"

PageDataDownload::PageDataDownload(QWidget* parent) : AbstractPage(parent)
{
    QGridLayout * pageLayout = new QGridLayout(this);
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 1);

    BtnBack = addButton(":/res/Exit.png", pageLayout, 1, 0, true);

    web = new QWebView(this);
    connect(this, SIGNAL(linkClicked(const QUrl&)), this, SLOT(install(const QUrl&)));
    web->load(QUrl("http://m8y.org/hw/downloads/"));
    web->page()->setLinkDelegationPolicy(QWebPage::DelegateAllLinks);
    pageLayout->addWidget(web, 0, 0, 1, 3);
}

void PageDataDownload::install(const QUrl &url)
{
qWarning("Download Request");
QString fileName = QFileInfo(url.toString()).fileName();

QNetworkRequest newRequest(url);
newRequest.setAttribute(QNetworkRequest::User, fileName);

QNetworkAccessManager *manager = new QNetworkAccessManager(this);
QNetworkReply *reply = manager->get(newRequest);
//connect( reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)) );
//connect( reply, SIGNAL(finished()), this, SLOT(downloadIssueFinished()));
}
