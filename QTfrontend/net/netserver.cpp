/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Igor Ulyanov <iulyanov@gmail.com>
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

#include "hwconsts.h"
#include "netserver.h"

HWNetServer::~HWNetServer()
{
    StopServer();
}

bool HWNetServer::StartServer(quint16 port)
{
    ds_port = port;

    QStringList params;
    params << QString("--port=%1").arg(port);
    params << "--dedicated=False";

    process.start(bindir->absolutePath() + "/hedgewars-server", params);

    return process.waitForStarted(5000);
}

void HWNetServer::StopServer()
{
    process.close();
}


quint16 HWNetServer::getRunningPort() const
{
    return ds_port;
}
