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

#ifndef PAGE_NET_H
#define PAGE_NET_H

#include "AbstractPage.h"

class PageNet : public AbstractPage
{
        Q_OBJECT

    public:
        PageNet(QWidget* parent = 0);

        QPushButton* BtnUpdateSList;
        QTableView * tvServersList;
        QPushButton * BtnNetConnect;
        QPushButton * BtnNetSvrStart;
        QPushButton * BtnSpecifyServer;

    public slots:
        void updateServersList();

    signals:
        void connectClicked(const QString & host, quint16 port, bool useTls);

    private:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

        QGroupBox * ConnGroupBox;
        QGridLayout * GBClayout;

    private slots:
        void slotConnect();
};

#endif

