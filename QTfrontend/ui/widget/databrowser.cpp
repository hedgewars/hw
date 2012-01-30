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
