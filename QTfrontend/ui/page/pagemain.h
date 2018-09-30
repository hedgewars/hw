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

#ifndef PAGE_MAIN_H
#define PAGE_MAIN_H

#include "AbstractPage.h"

class QIcon;

class PageMain : public AbstractPage
{
    Q_OBJECT

    public:
        PageMain(QWidget * parent = 0);
        void resetNetworkChoice();

        QPushButton * BtnSinglePlayer;
        QPushButton * BtnNet;
        QPushButton * BtnNetLocal;
        QPushButton * BtnNetOfficial;
        QPushButton * BtnSetup;
        QPushButton * BtnFeedback;
        QPushButton * BtnInfo;
        QPushButton * BtnDataDownload;
        QPushButton * BtnVideos;
        QPushButton * BtnHelp;
        QLabel * mainNote;

    private:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();
        QIcon originalNetworkIcon, disabledNetworkIcon;

        QString randomTip();
        QStringList Tips;

    private slots:
        void toggleNetworkChoice();
        void updateTip();
};

#endif

