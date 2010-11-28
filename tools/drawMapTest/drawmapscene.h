#ifndef DRAWMAPSCENE_H
#define DRAWMAPSCENE_H

#include <QGraphicsScene>

class QGraphicsPathItem;

class DrawMapScene : public QGraphicsScene
{
Q_OBJECT
public:
    explicit DrawMapScene(QObject *parent = 0);

signals:

public slots:
    void undo();

private:
    QPen m_pen;
    QBrush m_brush;
    QGraphicsPathItem  * m_currPath;

    virtual void mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent);
};

#endif // DRAWMAPSCENE_H
