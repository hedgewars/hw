/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2007 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef _NET_WWWSERVER_INCLUDED
#define _NET_WWWSERVER_INCLUDED

#include <QObject>
#include "netregister.h"

class HWNetWwwServer : public HWNetRegisterServer
{
	Q_OBJECT

public:
	HWNetWwwServer(QObject *parent, const QString & descr, quint16 port);

private slots:
	void onClientRead();

private:
};

#endif // _NET_WWWSERVER_INCLUDED
