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
    if(numHedgedogs < 8) numHedgedogs++;
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numHedgedogs > 3) numHedgedogs--;
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

  for(int i=0; i<numHedgedogs; i++) {
    QRect target(11 * i, i % 2, 25, 25);
    painter.drawImage(target, image);
  }
}
