#include <QUdpSocket>

#include "netudpserver.h"

#include <QDebug>

HWNetUdpServer::HWNetUdpServer(QObject* parent) :
  QObject(parent)
{
  pUdpSocket = new QUdpSocket(this);
  pUdpSocket->bind(46631);

  connect(pUdpSocket, SIGNAL(readyRead()), this, SLOT(onClientRead()));
  
}

void HWNetUdpServer::onClientRead()
{
  while (pUdpSocket->hasPendingDatagrams()) {
    QByteArray datagram;
    datagram.resize(pUdpSocket->pendingDatagramSize());
    QHostAddress clientAddr;
    quint16 clientPort;
    pUdpSocket->readDatagram(datagram.data(), datagram.size(), &clientAddr, &clientPort);
    if(QString("%1").arg(datagram.data())==QString("hedgewars client")) {
      // send answer to client
      qDebug() << "received UDP query from " << clientAddr << ":" << clientPort;
      pUdpSocket->writeDatagram("hedgewars server", clientAddr, clientPort);
    }
  }
}
