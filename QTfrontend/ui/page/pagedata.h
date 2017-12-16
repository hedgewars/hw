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

#ifndef PAGE_DATA_H
#define PAGE_DATA_H

#include <QUrl>
#include "AbstractPage.h"

class DataBrowser;
class QProgressBar;
class QNetworkReply;
class QVBoxLayout;


class PageDataDownload : public AbstractPage
{
        Q_OBJECT

    public:
        PageDataDownload(QWidget* parent = 0);

    public slots:
        void fetchList();

    protected:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

    private:
        DataBrowser *web;
        QHash<QNetworkReply*, QProgressBar *> progressBars;
        QVBoxLayout *progressBarsLayout;
        QPushButtonWithSound * pbOpenDir;
        QPushButtonWithSound * pbHome;

        bool m_contentDownloaded; ///< true if something was downloaded since last page leave

    private slots:
        void request(const QUrl &url);

        void pageDownloaded();
        void fileDownloaded();
        void downloadProgress(qint64, qint64);
        void openPackagesDir();

        void onPageLeave();
};

#endif
