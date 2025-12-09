#ifndef COLORWIDGET_H
#define COLORWIDGET_H

#include <QFrame>
#include <QModelIndex>

namespace Ui {
class ColorWidget;
}

class QStandardItemModel;

class ColorWidget : public QFrame {
  Q_OBJECT

 public:
  explicit ColorWidget(QStandardItemModel *colorsModel, QWidget *parent = 0);
  ~ColorWidget();

  void setColors(QStandardItemModel *colorsModel);
  void setColor(int color);
  int getColor();

 Q_SIGNALS:
  void colorChanged(int color);

 private:
  int m_color;
  QStandardItemModel *m_colorsModel;

 private Q_SLOTS:
  void dataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight);

 protected:
  void mousePressEvent(QMouseEvent *event);
  void wheelEvent(QWheelEvent *event);
  void nextColor();
  void previousColor();
};

#endif  // COLORWIDGET_H
