#ifndef _NET_UDPWIDGET_INCLUDED
#define _NET_UDPWIDGET_INCLUDED

#include <QWidget>
#include <QVBoxLayout>

class QUdpSocket;
class QListWidget;

class HWNetUdpWidget : public QWidget
{
  Q_OBJECT

 public:
  HWNetUdpWidget(QWidget *parent = 0);

 private slots:
  void onClientRead();

 private:
  QVBoxLayout mainLayout;
  QUdpSocket* pUdpSocket;
  QListWidget* serversList;
};

#endif // _NET_UDPWIDGET_INCLUDED
