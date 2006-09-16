#include "hedgehogerWidget.h"

#include <QMouseEvent>
#include <QPainter>

#include "frameTeam.h"

CHedgehogerWidget::CHedgehogerWidget(QWidget * parent) :
  QWidget(parent)
{
  if(parent) {
    pOurFrameTeams=dynamic_cast<FrameTeams*>(parent->parentWidget());
  }
  if(pOurFrameTeams->overallHedgehogs+4>pOurFrameTeams->maxHedgehogsPerGame) {
    numHedgehogs=pOurFrameTeams->maxHedgehogsPerGame-pOurFrameTeams->overallHedgehogs;
  } else numHedgehogs=4;
  pOurFrameTeams->overallHedgehogs+=numHedgehogs;
}

CHedgehogerWidget::~CHedgehogerWidget()
{
  pOurFrameTeams->overallHedgehogs-=numHedgehogs;
}

void CHedgehogerWidget::mousePressEvent ( QMouseEvent * event )
{
  if(event->button()==Qt::LeftButton) {
    event->accept();
    if(numHedgehogs < 8 && pOurFrameTeams->overallHedgehogs<18) {
      numHedgehogs++;
      pOurFrameTeams->overallHedgehogs++;
    }
  } else if (event->button()==Qt::RightButton) {
    event->accept();
    if(numHedgehogs > 3) {
      numHedgehogs--;
      pOurFrameTeams->overallHedgehogs--;
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
