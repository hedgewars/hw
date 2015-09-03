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

#include "proto.h"

HWProto::HWProto()
{

}

QByteArray & HWProto::addByteArrayToBuffer(QByteArray & buf, const QByteArray & msg)
{
    QByteArray bmsg = msg;
    bmsg = bmsg.left(250);
    quint8 sz = bmsg.size();
    buf.append(QByteArray((char *)&sz, 1));
    buf.append(bmsg);
    return buf;
}

QByteArray & HWProto::addStringToBuffer(QByteArray & buf, const QString & string)
{
    return addByteArrayToBuffer(buf, string.toUtf8());
}

QByteArray & HWProto::addStringListToBuffer(QByteArray & buf, const QStringList & strList)
{
    for (int i = 0; i < strList.size(); i++)
        addStringToBuffer(buf, strList[i]);
    return buf;
}

QString HWProto::formatChatMsg(const QString & nick, const QString & msg)
{
    if(msg.left(4) == "/me ")
        return QString("\x02* %1 %2").arg(nick).arg(msg.mid(4));
    else
        return QString("\x01%1: %2").arg(nick).arg(msg);
}

QString HWProto::chatStringToAction(const QString & string)
{
    if(string.left(4) == "/me ")
        return string.mid(4);
    else
        return QString();
}
