/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
    m_brush(Qt::yellow),
    m_cursor(new QGraphicsEllipseItem(-0.5, -0.5, 1, 1))
{
    setSceneRect(0, 0, 4096, 2048);

    QLinearGradient gradient(0, 0, 0, 2048);
    gradient.setColorAt(0, QColor(60, 60, 155));
    gradient.setColorAt(1, QColor(155, 155, 60));

    m_eraser = QBrush(gradient);
    setBackgroundBrush(m_eraser);
    m_isErasing = false;

    m_pen.setWidth(76);
    m_pen.setJoinStyle(Qt::RoundJoin);
    m_pen.setCapStyle(Qt::RoundCap);
    m_currPath = 0;

    m_isCursorShown = false;
    m_cursor->setPen(QPen(Qt::green));
    m_cursor->setZValue(1);
    m_cursor->setScale(m_pen.width());
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
            paths.first().points.append(mouseEvent->scenePos().toPoint());
        }
        m_currPath->setPath(path);

        emit pathChanged();
    }

    if(!m_isCursorShown)
        showCursor();
    m_cursor->setPos(mouseEvent->scenePos());
}

void DrawMapScene::mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    m_currPath = addPath(QPainterPath(), m_pen);

    QPainterPath path = m_currPath->path();
    QPointF p = mouseEvent->scenePos();
    p += QPointF(0.01, 0.01);
    path.moveTo(p);
    path.lineTo(mouseEvent->scenePos());

    PathParams params;
    params.width = serializePenWidth(m_pen.width());
    params.erasing = m_isErasing;
    params.points = QList<QPoint>() << mouseEvent->scenePos().toPoint();
    paths.prepend(params);
    m_currPath->setPath(path);

    emit pathChanged();
}

void DrawMapScene::mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    if (m_currPath)
    {
        QPainterPath path = m_currPath->path();
        path.lineTo(mouseEvent->scenePos());
        paths.first().points.append(mouseEvent->scenePos().toPoint());
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

    m_cursor->setScale(m_pen.width());

    if(m_currPath)
    {
        m_currPath->setPen(m_pen);
        paths.first().width = serializePenWidth(m_pen.width());
    }
}

void DrawMapScene::showCursor()
{
    if(!m_isCursorShown)
        addItem(m_cursor);

    m_isCursorShown = true;
}

void DrawMapScene::hideCursor()
{
    if(m_isCursorShown)
        removeItem(m_cursor);

    m_isCursorShown = false;
}

void DrawMapScene::undo()
{
    // cursor is a part of items()
    if(m_isCursorShown)
        return;

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
    // cursor is a part of items()
    if(m_isCursorShown)
        return;

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


void DrawMapScene::setErasing(bool erasing)
{
    m_isErasing = erasing;
    if(erasing)
        m_pen.setBrush(m_eraser);
    else
        m_pen.setBrush(m_brush);
}

QByteArray DrawMapScene::encode()
{
    QByteArray b;

    for(int i = paths.size() - 1; i >= 0; --i)
    {
        int cnt = 0;
        PathParams params = paths.at(i);
        foreach(QPoint point, params.points)
        {
            qint16 px = qToBigEndian((qint16)point.x());
            qint16 py = qToBigEndian((qint16)point.y());
            quint8 flags = 0;
            if(!cnt)
            {
                flags = 0x80 + params.width;
                if(params.erasing) flags |= 0x40;
            }
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
    bool erasing = m_isErasing;

    oldItems.clear();
    oldPaths.clear();
    clear();
    paths.clear();

    PathParams params;

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
            if(params.points.size())
            {
                addPath(pointsToPath(params.points), m_pen);

                paths.prepend(params);

                params.points.clear();
            }

            quint8 penWidth = flags & 0x3f;
            m_pen.setWidth(deserializePenWidth(penWidth));
            params.erasing = flags & 0x40;
            if(params.erasing)
                m_pen.setBrush(m_eraser);
            else
                m_pen.setBrush(m_brush);
            params.width = penWidth;
        }

        params.points.append(QPoint(px, py));
    }

    if(params.points.size())
    {
        addPath(pointsToPath(params.points), m_pen);
        paths.prepend(params);
    }

    emit pathChanged();

    setErasing(erasing);
}

void DrawMapScene::simplifyLast()
{
    if(!paths.size()) return;

    QList<QPoint> points = paths.at(0).points;

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

    paths[0].points = points;


    // redraw path
    {
        QGraphicsPathItem * pathItem = static_cast<QGraphicsPathItem *>(items()[m_isCursorShown ? 1 : 0]);
        pathItem->setPath(pointsToPath(paths[0].points));
    }

    emit pathChanged();
}

int DrawMapScene::pointsCount()
{
    int cnt = 0;
    foreach(PathParams p, paths)
        cnt += p.points.size();

    return cnt;
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
