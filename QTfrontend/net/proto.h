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
        static QByteArray & addByteArrayToBuffer(QByteArray & buf, const QByteArray & msg);
        static QByteArray & addStringListToBuffer(QByteArray & buf, const QStringList & strList);
        static QString formatChatMsg(const QString & nick, const QString & msg);
        static QString formatChatMsgForFrontend(const QString & msg);
        /**
         * @brief Determines if a chat string represents a chat action and returns the action.
         * @param string chat string
         * @return the action-message or NULL if message is no action
         */
        static QString chatStringToAction(const QString & string);
};

#endif // _PROTO_H
