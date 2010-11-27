#ifndef DRAWMAPSCENE_H
#define DRAWMAPSCENE_H

#include <QGraphicsScene>

class DrawMapScene : public QGraphicsScene
{
Q_OBJECT
public:
    explicit DrawMapScene(QObject *parent = 0);

signals:

public slots:

private:
    virtual void mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent);
};

#endif // DRAWMAPSCENE_H
