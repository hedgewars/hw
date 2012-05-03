/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QDebug>
#include <QProgressBar>
#include <QBuffer>

#include "pagedata.h"
#include "databrowser.h"
#include "hwconsts.h"
#include "DataManager.h"

#include "quazip.h"
#include "quazipfile.h"

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

void PageDataDownload::connectSignals()
{
    connect(web, SIGNAL(anchorClicked(QUrl)), this, SLOT(request(const QUrl&)));
    connect(this, SIGNAL(goBack()), this, SLOT(onPageLeave()));
}

PageDataDownload::PageDataDownload(QWidget* parent) : AbstractPage(parent)
{
    initPage();

    web->setOpenLinks(false);
//    fetchList();

    m_contentDownloaded = false;
}

void PageDataDownload::request(const QUrl &url)
{
    QUrl finalUrl;
    if(url.host().isEmpty())
        finalUrl = QUrl("http://www.hedgewars.org" + url.path());
    else
        finalUrl = url;

    if(url.path().endsWith(".zip"))
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

    if(reply)
    {
        QString html = QString::fromUtf8(reply->readAll());
        int begin = html.indexOf("<!-- BEGIN -->");
        int end = html.indexOf("<!-- END -->");
        if(begin != -1 && begin < end)
        {
            html.truncate(end);
            html.remove(0, begin);
        }
        web->setHtml(html);
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

        extractDataPack(&fileContents);
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
    request(QUrl("http://hedgewars.org/content.html"));
}

bool PageDataDownload::extractDataPack(QByteArray * buf)
{
    QBuffer buffer;
    buffer.setBuffer(buf);

    QuaZip zip;
    zip.setIoDevice(&buffer);
    if(!zip.open(QuaZip::mdUnzip))
    {
        qWarning("testRead(): zip.open(): %d", zip.getZipError());
        return false;
    }

    QuaZipFile file(&zip);

    QDir extractDir(*cfgdir);
    extractDir.cd("Data");

    for(bool more = zip.goToFirstFile(); more; more = zip.goToNextFile())
    {
        if(!file.open(QIODevice::ReadOnly))
        {
            qWarning("file.open(): %d", file.getZipError());
            return false;
        }


        QString fileName = file.getActualFileName();
        QString filePath = extractDir.filePath(fileName);
        if (fileName.endsWith("/"))
        {
            QFileInfo fi(filePath);
            QDir().mkpath(fi.filePath());
        }
        else
        {
            qDebug() << "Extracting" << filePath;
            QFile out(filePath);
            if(!out.open(QFile::WriteOnly))
            {
                qWarning() << "out.open():" << out.errorString();
                return false;
            }

            out.write(file.readAll());

            out.close();

            if(file.getZipError() != UNZ_OK)
            {
                qWarning("file.getFileName(): %d", file.getZipError());
                return false;
            }

            if(!file.atEnd())
            {
                qWarning("read all but not EOF");
                return false;
            }

            if (this->isVisible())
                m_contentDownloaded = true;
            else
                DataManager::instance().reload();
        }

        file.close();

        if(file.getZipError()!=UNZ_OK)
        {
            qWarning("file.close(): %d", file.getZipError());
            return false;
        }
    }

    zip.close();

    return true;
}


void PageDataDownload::onPageLeave()
{
    if (m_contentDownloaded)
    {
        m_contentDownloaded = false;
        DataManager::instance().reload();
    }
}
