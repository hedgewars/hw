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

#ifndef PAGE_ADMIN_H
#define PAGE_ADMIN_H

#include "AbstractPage.h"

class QTableWidget;

class PageAdmin : public AbstractPage
{
        Q_OBJECT

    public:
        PageAdmin(QWidget* parent = 0);

    public slots:
        void serverMessageNew(const QString & str);
        void serverMessageOld(const QString & str);
        void protocol(int proto);
        void setBansList(const QStringList & bans);

    signals:
        void setServerMessageNew(const QString & str);
        void setServerMessageOld(const QString & str);
        void setProtocol(int proto);
        void askServerVars();
        void clearAccountsCache();
        void bansListRequest();
        void removeBan(const QString &);
        void banIP(const QString & ip, const QString & reason, int seconds);
        void banNick(const QString & nick, const QString & reason, int seconds);

    protected:
        QLayout * bodyLayoutDefinition();
        void connectSignals();

    private:
        QLineEdit * leServerMessageNew;
        QLineEdit * leServerMessageOld;
        QPushButton * pbSetSM;
        QPushButton * pbAsk;
        QSpinBox * sbProtocol;
        QTextBrowser * tb;
        QPushButton * pbClearAccountsCache;
        QTableWidget * twBans;

    private slots:
        void smChanged();
        void onAddClicked();
        void onRemoveClicked();
        void onRefreshClicked();
};

#endif
