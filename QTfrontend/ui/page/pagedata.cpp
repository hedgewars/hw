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
#include <QPushButton>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QFileInfo>
#include <QFileDialog>
#include <QDebug>
#include <QProgressBar>
#include <QBuffer>
#include <QDesktopServices>

#include "pagedata.h"
#include "databrowser.h"
#include "hwconsts.h"
#include "DataManager.h"
#include "FileEngine.h"

QLayout * PageDataDownload::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();
    pageLayout->setColumnStretch(0, 1);
    pageLayout->setColumnStretch(1, 1);
    pageLayout->setColumnStretch(2, 1);

    web = new DataBrowser(this);
    pageLayout->addWidget(web, 0, 0, 1, 3);

    progressBarsLayout = new QVBoxLayout();
    pageLayout->addLayout(progressBarsLayout, 1, 0, 1, 3);
    return pageLayout;
}

QLayout * PageDataDownload::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();
    bottomLayout->setStretch(0, 1);

    pbHome = addButton(":/res/home.png", bottomLayout, 1, true, Qt::AlignBottom);
    pbHome->setMinimumHeight(50);
    pbHome->setMinimumWidth(50);
    pbHome->setWhatsThis(tr("Return to the start page"));

    pbOpenDir = addButton(tr("Open packages directory"), bottomLayout, 2, false, Qt::AlignBottom);
    pbOpenDir->setStyleSheet("padding: 5px 10px");
    pbOpenDir->setMinimumHeight(50);

    bottomLayout->setStretch(2, 1);

    return bottomLayout;
}

void PageDataDownload::connectSignals()
{
    connect(web, SIGNAL(anchorClicked(QUrl)), this, SLOT(request(const QUrl&)));
    connect(this, SIGNAL(goBack()), this, SLOT(onPageLeave()));
    connect(pbOpenDir, SIGNAL(clicked()), this, SLOT(openPackagesDir()));
    connect(pbHome, SIGNAL(clicked()), this, SLOT(fetchList()));
}

PageDataDownload::PageDataDownload(QWidget* parent) : AbstractPage(parent)
{
    initPage();

    web->setOpenLinks(false);
//    fetchList();
    web->setHtml(QString(
        "<center><h2>Hedgewars Downloadable Content</h2><br><br>"
        "<i>%1</i></center>")
        .arg(tr("Loading, please wait.")));
    m_contentDownloaded = false;
}

void PageDataDownload::request(const QUrl &url)
{
    QUrl finalUrl;
    if(url.isEmpty())
    {
        qWarning() << "Empty URL requested";
        return;
    }
    else if(url.host().isEmpty())
        finalUrl = QUrl("https://www.hedgewars.org" + url.path());
    else
        finalUrl = url;

    if(url.path().endsWith(".hwp") || url.path().endsWith(".zip"))
    {
        qWarning() << "Download Request" << url.toString();
        QString fileName = QFileInfo(url.toString()).fileName();

        QNetworkRequest newRequest(finalUrl);
        newRequest.setAttribute(QNetworkRequest::User, fileName);

        QNetworkAccessManager *manager = new QNetworkAccessManager(this);
        QNetworkReply *reply = manager->get(newRequest);
        connect(reply, SIGNAL(finished()), this, SLOT(fileDownloaded()));
        connect(reply, SIGNAL(downloadProgress(qint64, qint64)), this, SLOT(downloadProgress(qint64, qint64)));

        QProgressBar *progressBar = new QProgressBar(this);
        progressBarsLayout->addWidget(progressBar);
        progressBars.insert(reply, progressBar);
    }
    else
    {
        qWarning() << "Page Request" << url.toString();

        QNetworkRequest newRequest(finalUrl);

        QNetworkAccessManager *manager = new QNetworkAccessManager(this);
        QNetworkReply *reply = manager->get(newRequest);
        connect(reply, SIGNAL(finished()), this, SLOT(pageDownloaded()));
    }
}


void PageDataDownload::pageDownloaded()
{
    QNetworkReply * reply = qobject_cast<QNetworkReply *>(sender());

    if (reply && (reply->error() == QNetworkReply::NoError)) {
        QString html = QString::fromUtf8(reply->readAll());
        int begin = html.indexOf("<!-- BEGIN -->");
        int end = html.indexOf("<!-- END -->");
        if(begin != -1 && begin < end)
        {
            html.truncate(end);
            html.remove(0, begin);
        }
        web->setHtml(html);
    } else
        web->setHtml(QString(
            "<center><h2>Hedgewars Downloadable Content</h2><br><br>"
            "<p><i><h4>%1</i></h4></p></center>")
            .arg(tr("This page requires an internet connection.")));
}

void PageDataDownload::fileDownloaded()
{
    QNetworkReply * reply = qobject_cast<QNetworkReply *>(sender());

    if(reply)
    {
        QProgressBar *progressBar = progressBars.value(reply, 0);

        if(progressBar)
        {
            progressBars.remove(reply);
            progressBar->deleteLater();
        }

        QDir extractDir(*cfgdir);
        extractDir.cd("Data");

        QString fileName = extractDir.filePath(QFileInfo(reply->url().path()).fileName());
        if(fileName.endsWith(".zip"))
            fileName = fileName.left(fileName.length() - 4) + ".hwp";

        QFile out(fileName);
        if(!out.open(QFile::WriteOnly))
        {
            qWarning() << "out.open():" << out.errorString();
            return ;
        }

        out.write(reply->readAll());

        out.close();

        // now mount it
        FileEngineHandler::mount(fileName);
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
    request(QUrl("https://hedgewars.org/content.html"));
}

void PageDataDownload::onPageLeave()
{
    if (m_contentDownloaded)
    {
        m_contentDownloaded = false;
        //DataManager::instance().reload();
    }
}

void PageDataDownload::openPackagesDir()
{
    QString path = QDir::toNativeSeparators(cfgdir->absolutePath() + "/Data");
    QDesktopServices::openUrl(QUrl("file:///" + path));
}
