/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2008-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef _NETSERVER_INCLUDED
#define _NETSERVER_INCLUDED

#include <QObject>
#include <QProcess>

class HWNetServer : public QObject
{
    Q_OBJECT

public:
    ~HWNetServer();
    bool StartServer(quint16 port);
    void StopServer();
    QString getRunningHostName() const;
    quint16 getRunningPort() const;

private:
    quint16 ds_port;
    QProcess process;
};

#endif // _NETSERVER_INCLUDED
