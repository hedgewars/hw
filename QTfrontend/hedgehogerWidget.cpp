#include "hedgehogerWidget.h"

#include <QMouseEvent>
#include <QPainter>

int overallHedgehogs=0;

CHedgehogerWidget::CHedgehogerWidget(QWidget * parent) :
  QWidget(parent), numHedgehogs(4)
{
  overallHedgehogs+=numHedgehogs;
}

CHedgehogerWidget::~CHedgehogerWidget()
{
  overallHedgehogs-=numHedgehogs;
}

void CHedgehogerWidget::mousePressEvent ( QMouseEvent * event )
{
  if(event->button()==Qt::LeftButton) {
    event->accept();
    if(numHedgehogs < 8 && overallHedgehogs<18) {
      numHedgehogs++;
      overallHedgehogs++;
    }
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numHedgehogs > 3) {
      numHedgehogs--;
      overallHedgehogs--;
    }
  } else {
    event->ignore();
    return;
  }
  repaint();
}

void CHedgehogerWidget::paintEvent(QPaintEvent* event)
{
  QImage image(":/res/hh25x25.png");

  QPainter painter(this);

  for(int i=0; i<numHedgehogs; i++) {
    QRect target(11 * i, i % 2, 25, 25);
    painter.drawImage(target, image);
  }
}

unsigned char CHedgehogerWidget::getHedgehogsNum()
{
  return numHedgehogs;
}
