#include "hwmap.h"

#include "hwconsts.h"

#include <QMessageBox>

HWMap::HWMap() :
  m_isStarted(false)
{
}

void HWMap::getImage(std::string seed) 
{
  m_seed=seed;
  Start();
}

void HWMap::ClientDisconnect()
{
  QImage im((uchar*)(const char*)readbuffer, 256, 128, QImage::Format_Mono);
  im.setNumColors(2);

  IPCSocket->close();
  IPCSocket->deleteLater();
  IPCSocket = 0;
  IPCServer->close();
  deleteLater();
  
  emit ImageReceived(im);
}

void HWMap::ClientRead()
{
  readbuffer.append(IPCSocket->readAll());
}

void HWMap::SendToClientFirst()
{
  std::string toSend=std::string("eseed ")+m_seed;
  char ln=(char)toSend.length();
  IPCSocket->write(&ln, 1);
  IPCSocket->write(toSend.c_str(), ln);

  IPCSocket->write("\x01!", 2);
}

void HWMap::NewConnection()
{
  QTcpSocket * client = IPCServer->nextPendingConnection();
  if(!IPCSocket) {
    IPCServer->close();
    IPCSocket = client;
    connect(client, SIGNAL(disconnected()), this, SLOT(ClientDisconnect()));
    connect(client, SIGNAL(readyRead()), this, SLOT(ClientRead()));
    SendToClientFirst();
  } else {
    qWarning("2nd IPC client?!");
    client->disconnectFromHost();
  }
}

void HWMap::StartProcessError(QProcess::ProcessError error)
{
  QMessageBox::critical(0, tr("Error"),
			tr("Unable to run engine: %1 (")
			.arg(error) + bindir->absolutePath() + "/hwengine)");
}

void HWMap::Start()
{
  IPCServer = new QTcpServer(this);
  connect(IPCServer, SIGNAL(newConnection()), this, SLOT(NewConnection()));
  IPCServer->setMaxPendingConnections(1);
  IPCSocket = 0;
  if (!IPCServer->listen(QHostAddress::LocalHost, IPC_PORT)) {
    QMessageBox::critical(0, tr("Error"),
			  tr("Unable to start the server: %1.")
			  .arg(IPCServer->errorString()));
  }
  
  QProcess * process;
  QStringList arguments;
  process = new QProcess;
  connect(process, SIGNAL(error(QProcess::ProcessError)), this, SLOT(StartProcessError(QProcess::ProcessError)));
  arguments << "46631";
  arguments << "landpreview";
  process->start(bindir->absolutePath() + "/hwengine", arguments);
}
