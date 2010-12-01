#ifndef DRAWMAPSCENE_H
#define DRAWMAPSCENE_H

#include <QGraphicsScene>
#include <QPainterPath>

class QGraphicsPathItem;

typedef QList<QList<QPoint> > Paths;

class DrawMapScene : public QGraphicsScene
{
Q_OBJECT
public:
    explicit DrawMapScene(QObject *parent = 0);

    QByteArray encode();
    void decode(QByteArray data);

signals:
    void pathChanged();

public slots:
    void undo();
    void simplifyLast();

private:
    QPen m_pen;
    QBrush m_brush;
    QGraphicsPathItem  * m_currPath;
    Paths paths;

    virtual void mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent);
    virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent);

    QPainterPath pointsToPath(const QList<QPoint> points);
};

#endif // DRAWMAPSCENE_H
