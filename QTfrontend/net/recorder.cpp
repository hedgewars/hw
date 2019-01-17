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

#include <QString>
#include <QByteArray>

#include "recorder.h"
#include "gameuiconfig.h"
#include "hwconsts.h"
#include "game.h"
#include "util/MessageDialog.h"
#include "LibavInteraction.h"

// Encoding is memory expensive process, so we need to limit maximum number
// of simultaneous encoders.
static const int maxRecorders = 3;
static int numRecorders = 0;

static QList<HWRecorder*> queue;

HWRecorder::HWRecorder(GameUIConfig * config, const QString &prefix) :
    TCPBase(false, !config->language().isEmpty())
{
    this->config = config;
    this->prefix = prefix;
    item = 0;
    finished = false;
    aborted = false;
    name = prefix + "." + LibavInteraction::instance().getExtension(config->AVFormat());
}

HWRecorder::~HWRecorder()
{
    emit encodingFinished(finished);
    if (queue.empty())
        numRecorders--;
    else
        queue.takeFirst()->Start(false);
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
        switch (msg.at(1))
        {
        case '?':
            SendIPC("!");
            break;
        case 'p':
            emit onProgress((quint8(msg.at(2))*256.0 + quint8(msg.at(3)))*0.0001);
            break;
        case 'v':
            finished = true;
            break;
        case 'E':
            int size = msg.size();
            emit ErrorMessage(
                tr("A fatal ERROR occured while processing the video recording! "
                "The video could not be saved.\n\n"
                "As a workaround, you could try to reset the Hedgewars video recorder settings to the defaults.\n\n"
                "To report this error, please click the 'Feedback' button in the main menu!\n\n"
                "Last engine message:\n%1")
                .arg(QString::fromUtf8(msg.mid(2).left(size - 4))));
            return;
        }
    }
}

void HWRecorder::EncodeVideo(const QByteArray & record)
{
    toSendBuf = record;
    toSendBuf.replace(QByteArray("\x02TD"), QByteArray("\x02TV"));
    toSendBuf.replace(QByteArray("\x02TL"), QByteArray("\x02TV"));
    toSendBuf.replace(QByteArray("\x02TN"), QByteArray("\x02TV"));
    toSendBuf.replace(QByteArray("\x02TS"), QByteArray("\x02TV"));

    if (numRecorders < maxRecorders)
    {
        numRecorders++;
        Start(false); // run engine
    }
    else
        queue.push_back(this);
}

QStringList HWRecorder::getArguments()
{
    QStringList arguments;
    QRect resolution = config->rec_Resolution();
    QString nick = config->netNick().toUtf8().toBase64();

    arguments << "--internal";
    arguments << "--port";
    arguments << QString("%1").arg(ipc_port);
    arguments << "--prefix";
    arguments << datadir->absolutePath();
    arguments << "--user-prefix";
    arguments << cfgdir->absolutePath();
    arguments << "--locale";
    arguments << HWGame::tr("en.txt");
    arguments << "--frame-interval";
    arguments << QString::number(config->timerInterval());
    arguments << "--width";
    arguments << QString::number(resolution.width());
    arguments << "--height";
    arguments << QString::number(resolution.height());
    arguments << "--nosound";
    arguments << "--raw-quality";
    arguments << QString::number(config->translateQuality());
    arguments << "--stereo";
    arguments << QString::number(config->stereoMode());
    arguments << "--nomusic";
    arguments << "--volume";
    arguments << "0";
    if (config->isAltDamageEnabled())
        arguments << "--altdmg";
    if (!nick.isEmpty()) {
        arguments << "--nick";
        arguments << nick;
    }
    arguments << "--recorder";
    arguments << QString::number(config->rec_Framerate()); //cVideoFramerateNum
    arguments << "1"; //cVideoFramerateDen
    arguments << prefix;
    arguments << config->AVFormat();
    arguments << config->videoCodec();
// Could use a field to use quality instead. maybe quality could override bitrate - or just pass (and set) both.
// The library does support using both at once after all.
    arguments << QString::number(config->rec_Bitrate()*1024);
    if (config->recordAudio() && (config->isSoundEnabled() || config->isMusicEnabled()))
        arguments << config->audioCodec();
    else
        arguments << "no";

    return arguments;
}

bool HWRecorder::simultaneousRun()
{
    return true;
}

void HWRecorder::abort()
{
    queue.removeOne(this);
    aborted = true;
    deleteLater();
}
