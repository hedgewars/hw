#include <QDebug>
#include <QGraphicsSceneMouseEvent>

#include "drawmapscene.h"

DrawMapScene::DrawMapScene(QObject *parent) :
    QGraphicsScene(parent)
{
    setSceneRect(0, 0, 4096, 2048);
}

void DrawMapScene::mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent)
{

    qDebug() << "move" << mouseEvent->scenePos();
}

void DrawMapScene::mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    qDebug() << "press" << mouseEvent->scenePos();
}

void DrawMapScene::mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    qDebug() << "release" << mouseEvent->scenePos();
}
