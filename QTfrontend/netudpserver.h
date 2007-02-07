#ifndef _NET_UDPSERVER_INCLUDED
#define _NET_UDPSERVER_INCLUDED

#include <QObject>

class QUdpSocket;

class HWNetUdpServer : public QObject
{
  Q_OBJECT

 public:
  HWNetUdpServer(QObject *parent = 0);

 private slots:
  void onClientRead();

 private:
  QUdpSocket* pUdpSocket;
};

#endif // _NET_UDPSERVER_INCLUDED
