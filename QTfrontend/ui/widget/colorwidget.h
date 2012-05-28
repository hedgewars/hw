#ifndef COLORWIDGET_H
#define COLORWIDGET_H

#include <QWidget>
#include <QModelIndex>

namespace Ui {
class ColorWidget;
}

class QStandardItemModel;

class ColorWidget : public QWidget
{
    Q_OBJECT
    
public:
    explicit ColorWidget(QStandardItemModel *colorsModel, QWidget *parent = 0);
    ~ColorWidget();

    void setColors(QStandardItemModel * colorsModel);
    void setColor(int color);
    int getColor();

signals:
    void colorChanged(int color);
    
private:
    int m_color;
    QStandardItemModel * m_colorsModel;

private slots:
    void dataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight);

protected:
    void mousePressEvent(QMouseEvent * event);
    void wheelEvent(QWheelEvent * event);
};

#endif // COLORWIDGET_H
