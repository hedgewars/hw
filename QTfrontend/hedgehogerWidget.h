#ifndef _HEDGEHOGER_WIDGET
#define _HEDGEHOGER_WIDGET

#include <QWidget>

class FrameTeams;

class CHedgehogerWidget : public QWidget
{
  Q_OBJECT

 public:
  CHedgehogerWidget(QWidget * parent);
  ~CHedgehogerWidget();
  unsigned char getHedgehogsNum();

 protected:
  virtual void paintEvent(QPaintEvent* event);
  virtual void mousePressEvent ( QMouseEvent * event );
  
 private:
  CHedgehogerWidget();
  unsigned char numHedgehogs;
  FrameTeams* pOurFrameTeams;
};

#endif // _HEDGEHOGER_WIDGET
