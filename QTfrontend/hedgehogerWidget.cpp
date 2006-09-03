#include "hedgehogerWidget.h"

#include <QMouseEvent>
#include <QPainter>

CHedgehogerWidget::CHedgehogerWidget(QWidget * parent) :
  QWidget(parent), numHedgedogs(3)
{
}

void CHedgehogerWidget::mousePressEvent ( QMouseEvent * event )
{
  if(event->button()==Qt::LeftButton) {
    event->accept();
    numHedgedogs++;
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numHedgedogs!=0) numHedgedogs--;
  } else {
    event->ignore();
    return;
  }
  repaint();
}

void CHedgehogerWidget::paintEvent(QPaintEvent* event)
{
  QRectF source(0.0, 0.0, 32.0, 32.0);
  QImage image("../share/hedgewars/Data/Graphics/Hedgehog.png");

  QPainter painter(this);

  for(int i=0; i<numHedgedogs; i++) {
    QRectF target(0.0+12.5*i, 0.0, 25.0, 25.0);
    painter.drawImage(target, image, source);
  }
}
