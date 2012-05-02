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

#ifndef PAGE_ADMIN_H
#define PAGE_ADMIN_H

#include "AbstractPage.h"

class PageAdmin : public AbstractPage
{
        Q_OBJECT

    public:
        PageAdmin(QWidget* parent = 0);

    public slots:
        void serverMessageNew(const QString & str);
        void serverMessageOld(const QString & str);
        void protocol(int proto);

    signals:
        void setServerMessageNew(const QString & str);
        void setServerMessageOld(const QString & str);
        void setProtocol(int proto);
        void askServerVars();
        void clearAccountsCache();

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

    private slots:
        void smChanged();
};

#endif
