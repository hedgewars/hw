#include "hedgehogerWidget.h"

#include <QMouseEvent>
#include <QPainter>

CHedgehogerWidget::CHedgehogerWidget(QWidget * parent) :
  QWidget(parent), numHedgehogs(4)
{
}

void CHedgehogerWidget::mousePressEvent ( QMouseEvent * event )
{
  if(event->button()==Qt::LeftButton) {
    event->accept();
    if(numHedgehogs < 8) numHedgehogs++;
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numHedgehogs > 3) numHedgehogs--;
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
