/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2012 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#include <QGraphicsSceneMouseEvent>
#include <QGraphicsPathItem>
#include <QtEndian>
#include <QDebug>

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

    m_pen.setWidth(76);
    m_pen.setJoinStyle(Qt::RoundJoin);
    m_pen.setCapStyle(Qt::RoundCap);
    m_currPath = 0;
}

void DrawMapScene::mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    if(m_currPath && (mouseEvent->buttons() & Qt::LeftButton))
    {
        QPainterPath path = m_currPath->path();

        if(mouseEvent->modifiers() & Qt::ControlModifier)
        {
            int c = path.elementCount();
            QPointF pos = mouseEvent->scenePos();
            path.setElementPositionAt(c - 1, pos.x(), pos.y());

        }
        else
        {
            path.lineTo(mouseEvent->scenePos());
            paths.first().second.append(mouseEvent->scenePos().toPoint());
        }
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
    paths.prepend(qMakePair(serializePenWidth(m_pen.width()), QList<QPoint>() << mouseEvent->scenePos().toPoint()));
    m_currPath->setPath(path);

    emit pathChanged();
}

void DrawMapScene::mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    if (m_currPath)
    {
        QPainterPath path = m_currPath->path();
        path.lineTo(mouseEvent->scenePos());
        paths.first().second.append(mouseEvent->scenePos().toPoint());
        m_currPath->setPath(path);

        simplifyLast();

        m_currPath = 0;
    }
}

void DrawMapScene::wheelEvent(QGraphicsSceneWheelEvent * wheelEvent)
{
    if(wheelEvent->delta() > 0 && m_pen.width() < 516)
        m_pen.setWidth(m_pen.width() + 10);
    else if(wheelEvent->delta() < 0 && m_pen.width() >= 16)
        m_pen.setWidth(m_pen.width() - 10);

    if(m_currPath)
    {
        m_currPath->setPen(m_pen);
        paths.first().first = serializePenWidth(m_pen.width());
    }
}

void DrawMapScene::undo()
{
    if(items().size())
    {
        removeItem(items().first());
        paths.removeFirst();

        emit pathChanged();
    }
    else if(oldItems.size())
    {
        while(oldItems.size())
            addItem(oldItems.takeFirst());
        paths = oldPaths;

        emit pathChanged();
    }
}

void DrawMapScene::clearMap()
{
    // don't clear if already cleared
    if(!items().size())
        return;

    oldItems.clear();

    // do this since clear() would _destroy_ all items
    while(items().size())
    {
        oldItems.push_front(items().first());
        removeItem(items().first());
    }

    oldPaths = paths;

    paths.clear();

    emit pathChanged();
}

QByteArray DrawMapScene::encode()
{
    QByteArray b;

    for(int i = paths.size() - 1; i >= 0; --i)
    {
        int cnt = 0;
        QPair<quint8, QList<QPoint> > points = paths.at(i);
        foreach(QPoint point, points.second)
        {
            qint16 px = qToBigEndian((qint16)point.x());
            qint16 py = qToBigEndian((qint16)point.y());
            quint8 flags = 0;
            if(!cnt) flags = 0x80 + points.first;
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
    oldItems.clear();
    oldPaths.clear();
    clear();
    paths.clear();

    QPair<quint8, QList<QPoint> > points;

    while(data.size() >= 5)
    {
        qint16 px = qFromBigEndian(*(qint16 *)data.data());
        data.remove(0, 2);
        qint16 py = qFromBigEndian(*(qint16 *)data.data());
        data.remove(0, 2);
        quint8 flags = *(quint8 *)data.data();
        data.remove(0, 1);

        if(flags & 0x80)
        {
            if(points.second.size())
            {
                addPath(pointsToPath(points.second), m_pen);

                paths.prepend(points);

                points.second.clear();
            }

            quint8 penWidth = flags & 0x7f;
            m_pen.setWidth(deserializePenWidth(penWidth));
            points.first = penWidth;
        }

        points.second.append(QPoint(px, py));
    }

    if(points.second.size())
    {
        addPath(pointsToPath(points.second), m_pen);
        paths.prepend(points);
    }

    emit pathChanged();
}

void DrawMapScene::simplifyLast()
{
    if(!paths.size()) return;

    QList<QPoint> points = paths.at(0).second;

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

    paths[0].second = points;


    // redraw path
    {
        QGraphicsPathItem * pathItem = static_cast<QGraphicsPathItem *>(items()[0]);
        pathItem->setPath(pointsToPath(paths[0].second));
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

quint8 DrawMapScene::serializePenWidth(int width)
{
    return (width - 6) / 10;
}

int DrawMapScene::deserializePenWidth(quint8 width)
{
    return width * 10 + 6;
}
