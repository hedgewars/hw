#include <QGraphicsSceneMouseEvent>
#include <QGraphicsPathItem>
#include <QtEndian>

#include "drawmapscene.h"

template <class T> T sqr(const T & x)
{
    return x*x;
}

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
    if(m_currPath && (mouseEvent->buttons() & Qt::LeftButton))
    {
        QPainterPath path = m_currPath->path();
        path.lineTo(mouseEvent->scenePos());
        paths.first().append(mouseEvent->scenePos().toPoint());
        m_currPath->setPath(path);

        emit pathChanged();
    }
}

void DrawMapScene::mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    m_currPath = addPath(QPainterPath(), m_pen);

    QPainterPath path = m_currPath->path();
    QPointF p = mouseEvent->scenePos();
    p += QPointF(0.01, 0.01);
    path.moveTo(p);
    path.lineTo(mouseEvent->scenePos());
    paths.prepend(QList<QPoint>() << mouseEvent->scenePos().toPoint());
    m_currPath->setPath(path);

    emit pathChanged();
}

void DrawMapScene::mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    Q_UNUSED(mouseEvent);

    simplifyLast();

    m_currPath = 0;
}

void DrawMapScene::undo()
{
    if(items().size())
    {
        removeItem(items().first());
        paths.removeFirst();

        emit pathChanged();
    }
}

void DrawMapScene::clearMap()
{
    clear();
    paths.clear();

    emit pathChanged();
}

QByteArray DrawMapScene::encode()
{
    QByteArray b;

    for(int i = paths.size() - 1; i >= 0; --i)
    {
        int cnt = 0;
        QList<QPoint> points = paths.at(i);
        foreach(QPoint point, points)
        {
            qint16 px = qToBigEndian((qint16)point.x());
            qint16 py = qToBigEndian((qint16)point.y());
            quint8 flags = 2;
            if(!cnt) flags |= 0x80;
            b.append((const char *)&px, 2);
            b.append((const char *)&py, 2);
            b.append((const char *)&flags, 1);

            ++cnt;
        }

    }

    return b;
}

void DrawMapScene::decode(QByteArray data)
{
    clear();
    paths.clear();

    QList<QPoint> points;

    while(data.size() >= 5)
    {
        qint16 px = qFromBigEndian(*(qint16 *)data.data());
        data.remove(0, 2);
        qint16 py = qFromBigEndian(*(qint16 *)data.data());
        data.remove(0, 2);
        quint8 flags = *(quint8 *)data.data();
        data.remove(0, 1);

        if((flags & 0x80) && points.size())
        {
            addPath(pointsToPath(points), m_pen);
            paths.prepend(points);

            points.clear();
        }

        points.append(QPoint(px, py));
    }

    if(points.size())
    {
        addPath(pointsToPath(points), m_pen);
        paths.prepend(points);
    }

    emit pathChanged();
}

void DrawMapScene::simplifyLast()
{
    if(!paths.size()) return;

    QList<QPoint> points = paths.at(0);

    QPoint prevPoint = points.first();
    int i = 1;
    while(i < points.size())
    {
        if( (i != points.size() - 1)
            && (sqr(prevPoint.x() - points[i].x()) + sqr(prevPoint.y() - points[i].y()) < 1000)
          )
            points.removeAt(i);
        else
        {
            prevPoint = points[i];
            ++i;
        }
    }

    paths[0] = points;


    // redraw path
    {
        QGraphicsPathItem * pathItem = static_cast<QGraphicsPathItem *>(items()[0]);
        pathItem->setPath(pointsToPath(paths[0]));
    }

    emit pathChanged();
}

QPainterPath DrawMapScene::pointsToPath(const QList<QPoint> points)
{
    QPainterPath path;

    if(points.size())
    {
        QPointF p = points[0] + QPointF(0.01, 0.01);
        path.moveTo(p);

        foreach(QPoint p, points)
            path.lineTo(p);
    }

    return path;
}
