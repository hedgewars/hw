#include <QDebug>
#include <QGraphicsSceneMouseEvent>
#include <QGraphicsPathItem>

#include "drawmapscene.h"

DrawMapScene::DrawMapScene(QObject *parent) :
    QGraphicsScene(parent),
    m_pen(Qt::yellow),
    m_brush(Qt::yellow)
{
    setSceneRect(0, 0, 4096, 2048);

    QLinearGradient gradient(0, 0, 0, 2048);
    gradient.setColorAt(0, QColor(60, 60, 155));
    gradient.setColorAt(1, QColor(155, 155, 60));
    setBackgroundBrush(QBrush(gradient));

    m_pen.setWidth(67);
    m_pen.setJoinStyle(Qt::RoundJoin);
    m_pen.setCapStyle(Qt::RoundCap);
    m_currPath = 0;
}

void DrawMapScene::mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent)
{

    qDebug() << "move" << mouseEvent->scenePos();

    if(m_currPath && (mouseEvent->buttons() & Qt::LeftButton))
    {
        QPainterPath path = m_currPath->path();
        path.lineTo(mouseEvent->scenePos());
        m_currPath->setPath(path);
        //drawFigure(mouseEvent->scenePos());
    }
}

void DrawMapScene::mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    qDebug() << "press" << mouseEvent->scenePos();

    m_currPath = addPath(QPainterPath(), m_pen);

    QPainterPath path = m_currPath->path();
    QPointF p = mouseEvent->scenePos();
    p += QPointF(0.01, 0.01);
    path.moveTo(p);
    path.lineTo(mouseEvent->scenePos());
    m_currPath->setPath(path);

    //drawFigure(mouseEvent->scenePos());
}

void DrawMapScene::mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    qDebug() << "release" << mouseEvent->scenePos();

    m_currPath = 0;
}

void DrawMapScene::undo()
{
    if(items().size())
        removeItem(items().first());
}
