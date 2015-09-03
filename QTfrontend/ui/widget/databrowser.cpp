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

/**
 * @file
 * @brief DataBrowser class implementation
 */

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QDebug>
#include <QUrl>

#include "databrowser.h"

const QNetworkRequest::Attribute typeAttribute = (QNetworkRequest::Attribute)(QNetworkRequest::User + 1);
const QNetworkRequest::Attribute urlAttribute = (QNetworkRequest::Attribute)(QNetworkRequest::User + 2);

DataBrowser::DataBrowser(QWidget *parent) :
    QTextBrowser(parent)
{

    manager = new QNetworkAccessManager(this);
}

QVariant DataBrowser::loadResource(int type, const QUrl & name)
{
    if(type == QTextDocument::ImageResource || type == QTextDocument::StyleSheetResource)
    {
        if(resources.contains(name.toString()))
        {
            return resources.take(name.toString());
        }
        else if(!requestedResources.contains(name.toString()))
        {
            qDebug() << "Requesting resource" << name.toString();
            requestedResources.insert(name.toString());

            QNetworkRequest newRequest(QUrl("http://www.hedgewars.org" + name.toString()));
            newRequest.setAttribute(typeAttribute, type);
            newRequest.setAttribute(urlAttribute, name);

            QNetworkReply *reply = manager->get(newRequest);
            connect(reply, SIGNAL(finished()), this, SLOT(resourceDownloaded()));
        }
    }

    return QVariant();
}

void DataBrowser::resourceDownloaded()
{
    QNetworkReply * reply = qobject_cast<QNetworkReply *>(sender());

    if(reply)
    {
        int type = reply->request().attribute(typeAttribute).toInt();
        QUrl url = reply->request().attribute(urlAttribute).toUrl();
        resources.insert(url.toString(), reply->readAll());
        document()->addResource(type, reply->request().url(), QVariant());
        update();
    }
}
