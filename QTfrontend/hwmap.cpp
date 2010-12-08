/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006, 2007 Igor Ulyanov <iulyanov@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */

#include "hwconsts.h"
#include "hwmap.h"

HWMap::HWMap() :
  TCPBase(false)
{
}

HWMap::~HWMap()
{
}

void HWMap::getImage(std::string seed, int filter, MapGenerator mapgen, int maze_size, const QByteArray & drawMapData)
{
    m_seed = seed;
    templateFilter = filter;
    m_mapgen = mapgen;
    m_maze_size = maze_size;
    m_drawMapData = drawMapData;
    Start();
}

QStringList HWMap::setArguments()
{
    QStringList arguments;
    arguments << cfgdir->absolutePath();
    arguments << QString("%1").arg(ipc_port);
    arguments << "landpreview";
    return arguments;
}

void HWMap::onClientDisconnect()
{
    if (readbuffer.size() == 128 * 32 + 1)
    {
        quint8 *buf = (quint8*) readbuffer.constData();
        QImage im(buf, 256, 128, QImage::Format_Mono);
        im.setNumColors(2);
        emit HHLimitReceived(buf[128 * 32]);
        emit ImageReceived(im);
    }
}

void HWMap::SendToClientFirst()
{
    SendIPC(QString("eseed %1").arg(m_seed.c_str()).toLatin1());
    SendIPC(QString("e$template_filter %1").arg(templateFilter).toLatin1());
    SendIPC(QString("e$mapgen %1").arg(m_mapgen).toLatin1());

    switch (m_mapgen)
    {
        case MAPGEN_MAZE:
            SendIPC(QString("e$maze_size %1").arg(m_maze_size).toLatin1());

        case MAPGEN_DRAWN:
        {
            QByteArray data = m_drawMapData;
            while(data.size() > 0)
            {
                QByteArray tmp = data;
                tmp.truncate(230);
                SendIPC("edraw " + tmp);
                data.remove(0, 230);
            }
        }
        default: ;
    }

    SendIPC("!");
}
