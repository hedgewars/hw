/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef _TCPBASE_INCLUDED
#define _TCPBASE_INCLUDED

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QByteArray>
#include <QString>
#include <QDir>
#include <QProcess>
#include <QPointer>

#include <QImage>

#define MAXMSGCHARS 255

class TCPBase : public QObject
{
        Q_OBJECT

    public:
        TCPBase(bool demoMode, QObject * parent = 0);
        virtual ~TCPBase();

        virtual bool couldBeRemoved();

    signals:
        void isReadyNow();

    protected:
        bool m_hasStarted;
        quint16 ipc_port;

        void Start(bool couldCancelPreviousRequest);

        QByteArray readbuffer;

        QByteArray toSendBuf;
        QByteArray demo;

        void SendIPC(const QByteArray & buf);
        void RawSendIPC(const QByteArray & buf);

        virtual QStringList getArguments()=0;
        virtual void onClientRead();
        virtual void onClientDisconnect();
        virtual void SendToClientFirst();

    private:
        static QPointer<QTcpServer> IPCServer;

        bool m_isDemoMode;
        void RealStart();
        QPointer<QTcpSocket> IPCSocket;

    private slots:
        void NewConnection();
        void ClientDisconnect();
        void ClientRead();
        void StartProcessError(QProcess::ProcessError error);

        void tcpServerReady();
};

#ifdef HWLIBRARY
class EngineInstance : public QObject
{
    Q_OBJECT
public:
    EngineInstance(QObject *parent = 0);
    ~EngineInstance();

    int port;
public slots:
    void start(void);
signals:
    void finished(void);
private:
};
#endif

#endif // _TCPBASE_INCLUDED
