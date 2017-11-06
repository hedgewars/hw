/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
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

#include <QList>
#include <QImage>
#include <QThread>
#include <QApplication>

#include "tcpBase.h"
#include "hwconsts.h"
#include "MessageDialog.h"

#ifdef HWLIBRARY
extern "C" {
    void RunEngine(int argc, char ** argv);

    int operatingsystem_parameter_argc;
    char ** operatingsystem_parameter_argv;
}


EngineInstance::EngineInstance(QObject *parent)
    : QObject(parent)
{

}

EngineInstance::~EngineInstance()
{
    qDebug() << "EngineInstance delete" << QThread::currentThreadId();
}

void EngineInstance::setArguments(const QStringList & arguments)
{
    m_arguments.clear();
    m_arguments << qApp->arguments().at(0).toUtf8();

    m_argv.resize(arguments.size() + 1);
    m_argv[0] = m_arguments.last().data();

    int i = 1;
    foreach(const QString & s, arguments)
    {
        m_arguments << s.toUtf8();
        m_argv[i] = m_arguments.last().data();
        ++i;
    }
}

void EngineInstance::start()
{
    qDebug() << "EngineInstance start" << QThread::currentThreadId();

    RunEngine(m_argv.size(), m_argv.data());

    emit finished();
}

#endif

QList<TCPBase*> srvsList;
QPointer<QTcpServer> TCPBase::IPCServer(0);

TCPBase::~TCPBase()
{
    if(m_hasStarted)
    {
        if(IPCSocket)
            IPCSocket->close();

        if(m_connected)
        {
#ifdef HWLIBRARY
            if(!thread)
                qDebug("WTF");
            thread->quit();
            thread->wait();
#else
            process->waitForFinished(1000);
#endif
        }
    }
    // make sure this object is not in the server list anymore
    srvsList.removeOne(this);

    if (IPCSocket)
        IPCSocket->deleteLater();

}

TCPBase::TCPBase(bool demoMode, QObject *parent) :
    QObject(parent),
    m_hasStarted(false),
    m_isDemoMode(demoMode),
    m_connected(false),
    IPCSocket(0)
{
    process = 0;

    if(!IPCServer)
    {
        IPCServer = new QTcpServer(0);
        IPCServer->setMaxPendingConnections(1);
        if (!IPCServer->listen(QHostAddress::LocalHost))
        {
            MessageDialog::ShowFatalMessage(tr("Unable to start server at %1.").arg(IPCServer->errorString()));
            exit(0); // FIXME - should be graceful exit here (lower Critical -> Warning above when implemented)
        }
    }

    ipc_port=IPCServer->serverPort();
}

void TCPBase::NewConnection()
{
    if(IPCSocket)
    {
        // connection should be already finished
        return;
    }

    disconnect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
    IPCSocket = IPCServer->nextPendingConnection();

    if(!IPCSocket) return;

    m_connected = true;

    connect(IPCSocket, SIGNAL(disconnected()), this, SLOT(ClientDisconnect()));
    connect(IPCSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
    SendToClientFirst();

    if(simultaneousRun())
    {
        srvsList.removeOne(this);
        emit isReadyNow();
    }
}

void TCPBase::RealStart()
{
    connect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
    IPCSocket = 0;

#ifdef HWLIBRARY
    thread = new QThread(this);
    EngineInstance *instance = new EngineInstance();
    instance->setArguments(getArguments());

    instance->moveToThread(thread);

    connect(thread, SIGNAL(started()), instance, SLOT(start(void)));
    connect(instance, SIGNAL(finished()), thread, SLOT(quit()));
    connect(instance, SIGNAL(finished()), instance, SLOT(deleteLater()));
    connect(instance, SIGNAL(finished()), thread, SLOT(deleteLater()));
    thread->start();
#else
    process = new QProcess(this);
    connect(process, SIGNAL(error(QProcess::ProcessError)),
        this, SLOT(StartProcessError(QProcess::ProcessError)));
    connect(process, SIGNAL(finished(int, QProcess::ExitStatus)),
        this, SLOT(onEngineDeath(int, QProcess::ExitStatus)));
    QStringList arguments = getArguments();

#ifdef QT_DEBUG
    // redirect everything written on stdout/stderr
    process->setProcessChannelMode(QProcess::ForwardedChannels);
#endif

    process->start(bindir->absolutePath() + "/hwengine", arguments);
#endif
    m_hasStarted = true;
}

void TCPBase::ClientDisconnect()
{
    onClientDisconnect();

    if(!simultaneousRun())
    {
#ifdef HWLIBRARY
        thread->quit();
        thread->wait();
#endif
        emit isReadyNow();
    }

    if(IPCSocket) {
      disconnect(IPCSocket, SIGNAL(readyRead()), this, SLOT(ClientRead()));
      IPCSocket->deleteLater();
      IPCSocket = NULL;
    }

    deleteLater();
}

void TCPBase::ClientRead()
{
    QByteArray read = IPCSocket->readAll();
    if(read.isEmpty()) return;
    readbuffer.append(read);
    onClientRead();
}

void TCPBase::StartProcessError(QProcess::ProcessError error)
{
    MessageDialog::ShowFatalMessage(tr("Unable to run engine at %1\nError code: %2").arg(bindir->absolutePath() + "/hwengine").arg(error));
    ClientDisconnect();
}

void TCPBase::onEngineDeath(int exitCode, QProcess::ExitStatus exitStatus)
{
    Q_UNUSED(exitStatus);

    if(!m_connected)
      ClientDisconnect();

    // show error message if there was an error that was not an engine's
    // fatal error - because that one already sent a info via IPC
    if ((exitCode != 0) && (exitCode != 2))
    {
        // inform user that something bad happened
        MessageDialog::ShowFatalMessage(
            tr("The game engine died unexpectedly!\n"
            "(exit code %1)\n\n"
            "We are very sorry for the inconvenience :(\n\n"
            "If this keeps happening, please click the '%2' button in the main menu!")
            .arg(exitCode)
            .arg("Feedback"));

    }
}

void TCPBase::tcpServerReady()
{
    disconnect(srvsList.first(), SIGNAL(isReadyNow()), this, SLOT(tcpServerReady()));

    RealStart();
}

void TCPBase::Start(bool couldCancelPreviousRequest)
{
    if(srvsList.isEmpty())
    {
        srvsList.push_back(this);
        RealStart();
    }
    else
    {
        TCPBase * last = srvsList.last();
        if(couldCancelPreviousRequest
            && last->couldBeRemoved()
            && (last->isConnected() || !last->hasStarted())
            && (last->parent() == parent()))
        {
            srvsList.removeLast();
            delete last;
            Start(couldCancelPreviousRequest);
        } else
        {
            connect(last, SIGNAL(isReadyNow()), this, SLOT(tcpServerReady()));
            srvsList.push_back(this);
        }
    }
}

void TCPBase::onClientRead()
{
}

void TCPBase::onClientDisconnect()
{
}

void TCPBase::SendToClientFirst()
{
}

void TCPBase::SendIPC(const QByteArray & buf)
{
    if (buf.size() > MAXMSGCHARS) return;
    quint8 len = buf.size();
    RawSendIPC(QByteArray::fromRawData((char *)&len, 1) + buf);
}

void TCPBase::RawSendIPC(const QByteArray & buf)
{
    if (!IPCSocket)
    {
        toSendBuf += buf;
    }
    else
    {
        if (toSendBuf.size() > 0)
        {
            IPCSocket->write(toSendBuf);
            if(m_isDemoMode) demo.append(toSendBuf);
            toSendBuf.clear();
        }
        if(!buf.isEmpty())
        {
            IPCSocket->write(buf);
            if(m_isDemoMode) demo.append(buf);
        }
    }
}

bool TCPBase::couldBeRemoved()
{
    return false;
}

bool TCPBase::isConnected()
{
    return m_connected;
}

bool TCPBase::simultaneousRun()
{
    return false;
}

bool TCPBase::hasStarted()
{
    return m_hasStarted;
}
