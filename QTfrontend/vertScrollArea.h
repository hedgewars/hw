#ifndef _VERT_SCROLL_AREA_INCLUDED
#define _VERT_SCROLL_AREA_INCLUDED

#include <QScrollArea>

class VertScrArea : public QScrollArea
{
  Q_OBJECT

 public:
  VertScrArea(QColor frameColor, QWidget * parent = 0);

 protected:
  virtual void resizeEvent(QResizeEvent * event);
};

#endif // _VERT_SCROLL_AREA_INCLUDED
