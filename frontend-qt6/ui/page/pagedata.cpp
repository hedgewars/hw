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

    pbHome = addButton(QStringLiteral(":/res/home.png"), bottomLayout, 1, true, Qt::AlignBottom);
    pbHome->setMinimumHeight(50);
    pbHome->setMinimumWidth(50);
    pbHome->setWhatsThis(tr("Load the start page"));

    pbOpenDir = addButton(QStringLiteral(":/res/folder.png"), bottomLayout, 2, true, Qt::AlignBottom);
    pbOpenDir->setStyleSheet(QStringLiteral("padding: 5px 10px"));
    pbOpenDir->setWhatsThis(tr("Open packages directory"));
    pbOpenDir->setMinimumHeight(50);

    bottomLayout->setStretch(2, 1);

    return bottomLayout;
}

void PageDataDownload::connectSignals()
{
    connect(web, &QTextBrowser::anchorClicked, this, &PageDataDownload::request);
    connect(this, &AbstractPage::goBack, this, &PageDataDownload::onPageLeave);
    connect(pbOpenDir, &QAbstractButton::clicked, this, &PageDataDownload::openPackagesDir);
    connect(pbHome, &QAbstractButton::clicked, this, &PageDataDownload::fetchList);
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
        finalUrl = QUrl(QStringLiteral("https://www.hedgewars.org") + url.path());
    else
        finalUrl = url;

    if(url.path().endsWith(QLatin1String(".hwp")) || url.path().endsWith(QLatin1String(".zip")))
    {
        qWarning() << "Download Request" << url.toString();
        QString fileName = QFileInfo(url.toString()).fileName();

        QNetworkRequest newRequest(finalUrl);
        newRequest.setAttribute(QNetworkRequest::User, fileName);

        QNetworkAccessManager *manager = new QNetworkAccessManager(this);
        QNetworkReply *reply = manager->get(newRequest);
        connect(reply, &QNetworkReply::finished, this, &PageDataDownload::fileDownloaded);
        connect(reply, &QNetworkReply::downloadProgress, this, &PageDataDownload::downloadProgress);

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
        connect(reply, &QNetworkReply::finished, this, &PageDataDownload::pageDownloaded);
    }
}


void PageDataDownload::pageDownloaded()
{
    QNetworkReply * reply = qobject_cast<QNetworkReply *>(sender());
    const char *html =
        "<center><h2>Hedgewars Downloadable Content</h2><br><br>"
        "<h4><i>%1</i></h4></center>";

    if (reply) {
        if (reply->error() == QNetworkReply::NoError)
        {
            QString html = QString::fromUtf8(reply->readAll());
                    int begin = html.indexOf(QLatin1String("<!-- BEGIN -->"));
                    int end = html.indexOf(QLatin1String("<!-- END -->"));
                    if(begin != -1 && begin < end)
                    {
                        html.truncate(end);
                        html.remove(0, begin);
                    }
                    web->setHtml(html);
        }
        else
        {
            QString message = reply->error() == QNetworkReply::UnknownNetworkError ?
                tr("Unknown network error (possibly missing SSL library).") :
                QString(tr("This feature requires an Internet connection, but you don't appear to be online (error code: %1).")).arg(reply->error());
            web->setHtml(QString(html).arg(message));
        }
    }
    else {
        web->setHtml(QString(html).arg(tr("Internal error: Reply object is invalid.")));
    }
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

        QDir extractDir(cfgdir);
        extractDir.cd(QStringLiteral("Data"));

        QString fileName = extractDir.filePath(QFileInfo(reply->url().path()).fileName());
        if(fileName.endsWith(QLatin1String(".zip")))
            fileName = fileName.left(fileName.length() - 4) + QStringLiteral(".hwp");

        QFile out(fileName);
        if(!out.open(QFile::WriteOnly))
        {
            qWarning() << "out.open():" << out.errorString();
            return ;
        }

        out.write(reply->readAll());

        out.close();
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
    request(QUrl(QStringLiteral("https://hedgewars.org/content.html")));
}

void PageDataDownload::onPageLeave()
{
    if (m_contentDownloaded)
    {
        m_contentDownloaded = false;
    }
}

void PageDataDownload::openPackagesDir()
{
  QString path = QDir::toNativeSeparators(cfgdir.absolutePath() + QStringLiteral("/Data"));
  QDesktopServices::openUrl(QUrl(QStringLiteral("file:///") + path));
}
