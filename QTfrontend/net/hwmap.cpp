/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Ulyanov Igor <iulyanov@gmail.com>
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

#include <QPainter>
#include <QBitmap>
#include <QLinearGradient>

#include "hwconsts.h"
#include "hwmap.h"

HWMap::HWMap(QObject * parent) :
    TCPBase(false, parent)
{
    templateFilter = 0;
    m_mapgen = MAPGEN_REGULAR;
    m_maze_size = 0;
    m_feature_size = 50;
}

HWMap::~HWMap()
{
}

bool HWMap::couldBeRemoved()
{
    return !m_hasStarted;
}

void HWMap::getImage(const QString & seed, int filter, MapGenerator mapgen, int maze_size, const QByteArray & drawMapData, QString & script, QString & scriptparam, int feature_size)
{
    m_seed = seed;
    m_script = script;
    m_scriptparam = scriptparam;
    templateFilter = filter;
    m_mapgen = mapgen;
    m_maze_size = maze_size;
    m_feature_size = feature_size;
    if(mapgen == MAPGEN_DRAWN) m_drawMapData = drawMapData;
    Start(true);
}

QStringList HWMap::getArguments()
{
    QStringList arguments;
    arguments << "--internal";
    arguments << "--port";
    arguments << QString("%1").arg(ipc_port);
    arguments << "--user-prefix";
    arguments << cfgdir->absolutePath();
    arguments << "--prefix";
    arguments << datadir->absolutePath();
    arguments << "--landpreview";
    return arguments;
}

void HWMap::onClientDisconnect()
{    
    QLinearGradient linearGrad(QPoint(128, 0), QPoint(128, 128));
    linearGrad.setColorAt(1, QColor(0, 0, 192));
    linearGrad.setColorAt(0, QColor(66, 115, 225));

    if (readbuffer.size() == 128 * 32 + 1)
    {
        quint8 *buf = (quint8*) readbuffer.constData();
        QImage im(buf, 256, 128, QImage::Format_Mono);
        im.setNumColors(2);

        QPixmap px(QSize(256, 128));
        QPixmap pxres(px.size());
        QPainter p(&pxres);

        px.fill(Qt::yellow);
        QBitmap bm = QBitmap::fromImage(im);
        px.setMask(bm);

        p.fillRect(pxres.rect(), linearGrad);
        p.drawPixmap(0, 0, px);

        emit HHLimitReceived(buf[128 * 32]);
        emit ImageReceived(px);
    } else if (readbuffer.size() == 128 * 256 + 1)
    {
        QVector<QRgb> colorTable;
        colorTable.resize(256);
        for(int i = 0; i < 256; ++i)
            colorTable[i] = qRgba(255, 255, 0, i);

        const quint8 *buf = (const quint8*) readbuffer.constData();
        QImage im(buf, 256, 128, QImage::Format_Indexed8);
        im.setColorTable(colorTable);

        QPixmap px = QPixmap::fromImage(im, Qt::ColorOnly);
        QPixmap pxres(px.size());
        QPainter p(&pxres);

        p.fillRect(pxres.rect(), linearGrad);
        p.drawPixmap(0, 0, px);

        emit HHLimitReceived(buf[128 * 256]);
        emit ImageReceived(px);
    }
}

void HWMap::SendToClientFirst()
{
    SendIPC(QString("eseed %1").arg(m_seed).toUtf8());
    SendIPC(QString("e$template_filter %1").arg(templateFilter).toUtf8());
    SendIPC(QString("e$mapgen %1").arg(m_mapgen).toUtf8());
    SendIPC(QString("e$feature_size %1").arg(m_feature_size).toUtf8());
    if (!m_script.isEmpty())
    {
        SendIPC(QString("escript Scripts/Multiplayer/%1.lua").arg(m_script).toUtf8());
        SendIPC(QString("e$scriptparam %1").arg(m_scriptparam).toUtf8());
    }

    switch (m_mapgen)
    {
        case MAPGEN_MAZE:
        case MAPGEN_PERLIN:
            SendIPC(QString("e$maze_size %1").arg(m_maze_size).toUtf8());
            break;

        case MAPGEN_DRAWN:
        {
            QByteArray data = m_drawMapData;
            while(data.size() > 0)
            {
                QByteArray tmp = data;
                tmp.truncate(200);
                SendIPC("edraw " + tmp);
                data.remove(0, 200);
            }
            break;
        }
        default:
            ;
    }

    SendIPC("!");
}
