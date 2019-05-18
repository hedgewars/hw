#include <QStandardItemModel>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QColor>

#include "colorwidget.h"
#include "hwconsts.h"

ColorWidget::ColorWidget(QStandardItemModel *colorsModel, QWidget *parent) :
    QFrame(parent)
{
    m_colorsModel = colorsModel;

    setColor(0);
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

    setStyleSheet(QString("* { border: 2px solid #ffcc00; border-radius: 8px; background: %1 } :disabled { border-color: #a0a0a0; } :hover { border-color: #ffff00; }").arg(item->data().value<QColor>().name()));
    /*
    QPalette p = palette();
    p.setColor(QPalette::Window, item->data().value<QColor>());
    setPalette(p);
    */

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
            nextColor();
            break;
        case Qt::RightButton:
            previousColor();
            break;
        default:;
    }
}

void ColorWidget::wheelEvent(QWheelEvent *event)
{
    if(event->delta() > 0)
        previousColor();
    else
        nextColor();
}

void ColorWidget::nextColor()
{
    setColor((m_color + 1) % m_colorsModel->rowCount());
}

void ColorWidget::previousColor()
{
    setColor((m_color + m_colorsModel->rowCount() - 1) % m_colorsModel->rowCount());
}
