#include <QDebug>
#include <QGraphicsSceneMouseEvent>

#include "drawmapscene.h"

DrawMapScene::DrawMapScene(QObject *parent) :
    QGraphicsScene(parent),
    m_pen(Qt::black),
    m_brush(Qt::black)
{
    setSceneRect(0, 0, 4096, 2048);

    QLinearGradient gradient(0, 0, 0, 2048);
    gradient.setColorAt(0, QColor(160, 160, 255));
    gradient.setColorAt(1, QColor(255, 255, 160));
    setBackgroundBrush(QBrush(gradient));

    m_halfWidth = 67;
}

void DrawMapScene::mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent)
{

    qDebug() << "move" << mouseEvent->scenePos();

    if(mouseEvent->buttons() && Qt::LeftButton)
        drawFigure(mouseEvent->scenePos());
}

void DrawMapScene::mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    qDebug() << "press" << mouseEvent->scenePos();

    drawFigure(mouseEvent->scenePos());
}

void DrawMapScene::mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    qDebug() << "release" << mouseEvent->scenePos();
}

void DrawMapScene::drawFigure(const QPointF & point)
{
    addEllipse(
            point.x() - m_halfWidth,
            point.y() - m_halfWidth,
            m_halfWidth * 2,
            m_halfWidth * 2,
            m_pen,
            m_brush
        );
}
