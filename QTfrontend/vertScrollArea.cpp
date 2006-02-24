#include "vertScrollArea.h"

#include <QResizeEvent>

VertScrArea::VertScrArea(QColor frameColor, QWidget * parent) :
  QScrollArea(parent)
{
  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Background, frameColor);
  setPalette(newPalette);
}

void VertScrArea::resizeEvent(QResizeEvent * event)
{
  widget()->resize(event->size().width(), widget()->sizeHint().height());
}
