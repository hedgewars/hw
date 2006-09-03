#ifndef _HEDGEHOGER_WIDGET
#define _HEDGEHOGER_WIDGET

#include <QWidget>

class CHedgehogerWidget : public QWidget
{
  Q_OBJECT

 public:
  CHedgehogerWidget(QWidget * parent = 0);

 protected:
  virtual void paintEvent(QPaintEvent* event);
  virtual void mousePressEvent ( QMouseEvent * event );
  
 private:
  unsigned char numHedgedogs;
};

#endif // _HEDGEHOGER_WIDGET
