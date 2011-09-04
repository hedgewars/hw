#ifndef DATABROWSER_H
#define DATABROWSER_H

#include <QTextBrowser>
#include <QSet>

class QNetworkAccessManager;

class DataBrowser : public QTextBrowser
{
    Q_OBJECT
public:
    explicit DataBrowser(QWidget *parent = 0);

signals:

public slots:

private:
    QNetworkAccessManager *manager;
    QHash<QUrl, QByteArray> resources;
    QSet<QUrl> requestedResources;

    QVariant loadResource(int type, const QUrl & name);

private slots:
    void resourceDownloaded();
};

#endif // DATABROWSER_H
