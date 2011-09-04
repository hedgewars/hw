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
#include <QNetworkReply>
#include <QFileInfo>
#include <QFileDialog>
#include <QTextBrowser>
#include <QDebug>
#include <QProgressBar>

#include "pagedata.h"

#include "quazip.h"

PageDataDownload::PageDataDownload(QWidget* parent) : AbstractPage(parent)
{
    QGridLayout * pageLayout = new QGridLayout(this);
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 1);

    BtnBack = addButton(":/res/Exit.png", pageLayout, 2, 0, true);

    web = new QTextBrowser(this);
    connect(web, SIGNAL(anchorClicked(QUrl)), this, SLOT(install(const QUrl&)));
    web->setOpenLinks(false);
    pageLayout->addWidget(web, 0, 0, 1, 3);

    progressBarsLayout = new QVBoxLayout(this);
    pageLayout->addLayout(progressBarsLayout, 1, 0, 1, 3);

    fetchList();
}

void PageDataDownload::install(const QUrl &url)
{
    qWarning() << "Download Request" << url.toString();
    QString fileName = QFileInfo(url.toString()).fileName();

    QNetworkRequest newRequest(url);
    newRequest.setAttribute(QNetworkRequest::User, fileName);

    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    QNetworkReply *reply = manager->get(newRequest);
    connect(reply, SIGNAL(finished()), this, SLOT(fileDownloaded()));
    connect(reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)));

    QProgressBar *progressBar = new QProgressBar(this);
    progressBarsLayout->addWidget(progressBar);
    progressBars.insert(reply, progressBar);
}


void PageDataDownload::pageDownloaded()
{
    QNetworkReply * reply = qobject_cast<QNetworkReply *>(sender());

    if(reply)
    {
        web->setHtml(QString::fromUtf8(reply->readAll()));
    }
}

void PageDataDownload::fileDownloaded()
{
    QNetworkReply * reply = qobject_cast<QNetworkReply *>(sender());

    if(reply)
    {
        QByteArray fileContents = reply->readAll();
        QProgressBar *progressBar = progressBars.value(reply, 0);

        if(progressBar)
        {
            progressBars.remove(reply);
            progressBar->deleteLater();
        }
    }
}

void PageDataDownload::downloadProgress(qint64 bytesRecieved, qint64 bytesTotal)
{
    QNetworkReply * reply = qobject_cast<QNetworkReply *>(sender());

    if(reply)
    {
        QProgressBar *progressBar = progressBars.value(reply, 0);

        if(progressBar)
        {
            progressBar->setValue(bytesRecieved);
            progressBar->setMaximum(bytesTotal);
        }
    }
}

void PageDataDownload::fetchList()
{
    QNetworkRequest newRequest(QUrl("http://hedgewars.org/download.html"));

    QNetworkAccessManager *manager = new QNetworkAccessManager(this);
    QNetworkReply *reply = manager->get(newRequest);
    connect(reply, SIGNAL(finished()), this, SLOT(pageDownloaded()));
}
