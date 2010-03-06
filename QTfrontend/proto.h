/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef _PROTO_H
#define _PROTO_H

#include <QByteArray>
#include <QString>
#include <QStringList>


class HWProto : public QObject
{
    Q_OBJECT

public:
    HWProto();
    static QByteArray & addStringToBuffer(QByteArray & buf, const QString & string);
    static QByteArray & addStringListToBuffer(QByteArray & buf, const QStringList & strList);
    static QString formatChatMsg(const QString & nick, const QString & msg);
};

#endif // _PROTO_H
