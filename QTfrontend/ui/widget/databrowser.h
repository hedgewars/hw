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

        // hash and set of QString instead of QUrl to support Qt versions
        // older than 4.7 (those have no support for qHash(const QUrl &))
        QHash<QString, QByteArray> resources;
        QSet<QString> requestedResources;

        QVariant loadResource(int type, const QUrl & name);

    private slots:
        void resourceDownloaded();
};

#endif // DATABROWSER_H
