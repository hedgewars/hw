#ifndef DRAWMAPSCENE_H
#define DRAWMAPSCENE_H

#include <QGraphicsScene>

class QGraphicsPathItem;

typedef QList<QList<QPoint> > Paths;

class DrawMapScene : public QGraphicsScene
{
Q_OBJECT
public:
    explicit DrawMapScene(QObject *parent = 0);

    QByteArray encode();

signals:
    void pathChanged();

public slots:
    void undo();
    void simplify();

private:
    QPen m_pen;
    QBrush m_brush;
    QGraphicsPathItem  * m_currPath;
    Paths paths;

    virtual void mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent);
};

#endif // DRAWMAPSCENE_H
