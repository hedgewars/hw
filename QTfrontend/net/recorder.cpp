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

#include <QString>
#include <QByteArray>

#include "recorder.h"
#include "gameuiconfig.h"
#include "hwconsts.h"
#include "game.h"

HWRecorder::HWRecorder(GameUIConfig * config) :
    TCPBase(false)
{
    this->config = config;
}

HWRecorder::~HWRecorder()
{
}

void HWRecorder::onClientDisconnect()
{
}
     
void HWRecorder::onClientRead()
{
    quint8 msglen;
    quint32 bufsize;
    while (!readbuffer.isEmpty() && ((bufsize = readbuffer.size()) > 0) &&
            ((msglen = readbuffer.data()[0]) < bufsize))
    {
        QByteArray msg = readbuffer.left(msglen + 1);
        readbuffer.remove(0, msglen + 1);
        if (msg.at(1) == '?')
            SendIPC("!");
    }
}

void HWRecorder::EncodeVideo( const QByteArray & record, const QString & prefix )
{
    this->prefix = prefix;

    toSendBuf = record;
    toSendBuf.replace(QByteArray("\x02TD"), QByteArray("\x02TV"));
    toSendBuf.replace(QByteArray("\x02TL"), QByteArray("\x02TV"));
    toSendBuf.replace(QByteArray("\x02TN"), QByteArray("\x02TV"));
    toSendBuf.replace(QByteArray("\x02TS"), QByteArray("\x02TV"));

    // run engine
    Start();
}

QStringList HWRecorder::getArguments()
{
    QStringList arguments;
    QRect resolution = config->vid_Resolution();
    arguments << cfgdir->absolutePath();
    arguments << QString::number(resolution.width());
    arguments << QString::number(resolution.height());
    arguments << QString::number(config->bitDepth()); // bpp
    arguments << QString("%1").arg(ipc_port);
    arguments << "0"; // fullscreen
    arguments << "0"; // sound
    arguments << "0"; // music
    arguments << "0"; // sound volume
    arguments << QString::number(config->timerInterval());
    arguments << datadir->absolutePath();
    arguments << (config->isShowFPSEnabled() ? "1" : "0");
    arguments << (config->isAltDamageEnabled() ? "1" : "0");
    arguments << config->netNick().toUtf8().toBase64();
    arguments << QString::number(config->translateQuality());
    arguments << QString::number(config->stereoMode());
    arguments << HWGame::tr("en.txt");
    arguments << prefix;

    return arguments;
}
