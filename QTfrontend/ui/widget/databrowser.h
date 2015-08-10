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
 * @brief DataBrowser class definition
 */

#ifndef HEDGEWARS_DATABROWSER_H
#define HEDGEWARS_DATABROWSER_H

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

#endif // HEDGEWARS_DATABROWSER_H
