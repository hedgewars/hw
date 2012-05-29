#include <QStandardItemModel>
#include <QMouseEvent>
#include <QWheelEvent>

#include "colorwidget.h"
#include "hwconsts.h"

ColorWidget::ColorWidget(QStandardItemModel *colorsModel, QWidget *parent) :
    QWidget(parent)
{
    m_colorsModel = colorsModel;

    setColor(0);
    setStyleSheet("");
    setAutoFillBackground(true);

    connect(m_colorsModel, SIGNAL(dataChanged(QModelIndex,QModelIndex)), this, SLOT(dataChanged(QModelIndex,QModelIndex)));
}

ColorWidget::~ColorWidget()
{

}

void ColorWidget::setColor(int color)
{
    Q_ASSERT_X(color >= 0 && color < m_colorsModel->rowCount(), "ColorWidget::setColor", "Color index out of range");

    m_color = color;

    QStandardItem * item = m_colorsModel->item(m_color);

    QPalette p = palette();
    p.setColor(QPalette::Window, item->data().value<QColor>());
    setPalette(p);

    emit colorChanged(m_color);
}

int ColorWidget::getColor()
{
    return m_color;
}

void ColorWidget::dataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRight)
{
    if(m_color >= topLeft.row() && m_color <= bottomRight.row())
        setColor(m_color);
}

void ColorWidget::mousePressEvent(QMouseEvent * event)
{
    switch(event->button())
    {
        case Qt::LeftButton:
            setColor((m_color + 1) % m_colorsModel->rowCount());
            break;
        case Qt::RightButton:
            setColor((m_color + m_colorsModel->rowCount() - 1) % m_colorsModel->rowCount());
            break;
        default:;
    }
}

void ColorWidget::wheelEvent(QWheelEvent *event)
{
    if(event->delta() > 0)
        setColor((m_color + 1) % m_colorsModel->rowCount());
    else
        setColor((m_color + m_colorsModel->rowCount() - 1) % m_colorsModel->rowCount());
}
