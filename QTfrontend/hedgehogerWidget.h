#ifndef _HEDGEHOGER_WIDGET
#define _HEDGEHOGER_WIDGET

#include <QWidget>

class CHedgehogerWidget : public QWidget
{
  Q_OBJECT

 public:
  CHedgehogerWidget(QWidget * parent = 0);
  unsigned char getHedgehogsNum();

 protected:
  virtual void paintEvent(QPaintEvent* event);
  virtual void mousePressEvent ( QMouseEvent * event );
  
 private:
  unsigned char numHedgehogs;
};

#endif // _HEDGEHOGER_WIDGET
