/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef _NET_REGISTER_INCLUDED
#define _NET_REGISTER_INCLUDED

#include <QObject>

class HWNetRegisterServer : public QObject
{
    Q_OBJECT

public:
    HWNetRegisterServer(QObject *parent, const QString & descr, quint16 port);

public slots:
    virtual void unregister();
};

#endif // _NET_REGISTER_INCLUDED
