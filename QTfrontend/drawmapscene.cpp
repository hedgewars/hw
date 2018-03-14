/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QGraphicsSceneMouseEvent>
#include <QGraphicsPathItem>
#include <QtEndian>
#include <QDebug>
#include <QTransform>
#include <math.h>

#include "drawmapscene.h"

#define DRAWN_MAP_COLOR_LAND (Qt::yellow)
#define DRAWN_MAP_COLOR_CURSOR_PEN (Qt::green)
#define DRAWN_MAP_COLOR_CURSOR_ERASER (Qt::red)

template <class T> T sqr(const T & x)
{
    return x*x;
}

DrawMapScene::DrawMapScene(QObject *parent) :
    QGraphicsScene(parent),
    m_pen(DRAWN_MAP_COLOR_LAND),
    m_brush(DRAWN_MAP_COLOR_LAND),
    m_cursor(new QGraphicsEllipseItem(-5, -5, 5, 5))
{
    setSceneRect(0, 0, 4096, 2048);

    QLinearGradient gradient(0, 0, 0, 2048);
    gradient.setColorAt(0, QColor(60, 60, 155));
    gradient.setColorAt(1, QColor(155, 155, 60));

    m_eraser = QBrush(gradient);
    setBackgroundBrush(m_eraser);
    m_isErasing = false;

    m_pathType = Polyline;

    m_pen.setWidth(76);
    m_pen.setJoinStyle(Qt::RoundJoin);
    m_pen.setCapStyle(Qt::RoundCap);
    m_currPath = 0;

    m_isCursorShown = false;
    QPen cursorPen = QPen(DRAWN_MAP_COLOR_CURSOR_PEN);
    cursorPen.setJoinStyle(Qt::RoundJoin);
    cursorPen.setCapStyle(Qt::RoundCap);
    cursorPen.setWidth(m_pen.width());
    m_cursor->setPen(cursorPen);
    m_cursor->setZValue(1);
}

void DrawMapScene::mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    if(m_currPath && (mouseEvent->buttons() & Qt::LeftButton))
    {
        QPainterPath path = m_currPath->path();
        QPointF currentPos = mouseEvent->scenePos();

        if(mouseEvent->modifiers() & Qt::ControlModifier)
            currentPos = putSomeConstraints(paths.first().initialPoint, currentPos);

        switch (m_pathType)
        {
        case Polyline:
            if(mouseEvent->modifiers() & Qt::ControlModifier)
            {
                int c = path.elementCount();
                path.setElementPositionAt(c - 1, currentPos.x(), currentPos.y());

            }
            else
            {
                path.lineTo(currentPos);
                paths.first().points.append(mouseEvent->scenePos().toPoint());
            }
            break;
        case Rectangle: {
            path = QPainterPath();
            QPointF p1 = paths.first().initialPoint;
            QPointF p2 = currentPos;
            path.moveTo(p1);
            path.lineTo(p1.x(), p2.y());
            path.lineTo(p2);
            path.lineTo(p2.x(), p1.y());
            path.lineTo(p1);
            break;
            }
        case Ellipse: {
            path = QPainterPath();
            QList<QPointF> points = makeEllipse(paths.first().initialPoint, currentPos);
            path.addPolygon(QPolygonF(QVector<QPointF>::fromList(points)));
            break;
        }
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
    params.initialPoint = mouseEvent->scenePos().toPoint();
    params.points = QList<QPoint>() << params.initialPoint;
    paths.prepend(params);
    m_currPath->setPath(path);

    emit pathChanged();
}

void DrawMapScene::mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent)
{
    if (m_currPath)
    {
        QPointF currentPos = mouseEvent->scenePos();

        if(mouseEvent->modifiers() & Qt::ControlModifier)
            currentPos = putSomeConstraints(paths.first().initialPoint, currentPos);

        switch (m_pathType)
        {
        case Polyline: {
            QPainterPath path = m_currPath->path();
            path.lineTo(mouseEvent->scenePos());
            paths.first().points.append(currentPos.toPoint());
            m_currPath->setPath(path);
            simplifyLast();
            break;
        }
        case Rectangle: {
            QPoint p1 = paths.first().initialPoint;
            QPoint p2 = currentPos.toPoint();
            QList<QPoint> rpoints;
            rpoints << p1 << QPoint(p1.x(), p2.y()) << p2 << QPoint(p2.x(), p1.y()) << p1;
            paths.first().points = rpoints;
            break;
        }
        case Ellipse:
            QPoint p1 = paths.first().initialPoint;
            QPoint p2 = currentPos.toPoint();
            QList<QPointF> points = makeEllipse(p1, p2);
            QList<QPoint> epoints;
            foreach(const QPointF & p, points)
                epoints.append(p.toPoint());
            paths.first().points = epoints;
            break;
        }

        m_currPath = 0;

        emit pathChanged();
    }
}

void DrawMapScene::wheelEvent(QGraphicsSceneWheelEvent * wheelEvent)
{
    if(wheelEvent->delta() > 0 && m_pen.width() < 516)
        m_pen.setWidth(m_pen.width() + 10);
    else if(wheelEvent->delta() < 0 && m_pen.width() >= 16)
        m_pen.setWidth(m_pen.width() - 10);

    QPen cursorPen = m_cursor->pen();
    cursorPen.setWidth(m_pen.width());
    m_cursor->setPen(cursorPen);

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

    if(paths.size())
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

    m_specialPoints.clear();
    oldItems.clear();

    // do this since clear() would _destroy_ all items
    for(int i = paths.size() - 1; i >= 0; --i)
    {
        oldItems.push_front(items().first());
        removeItem(items().first());
    }

    items().clear();

    oldPaths = paths;

    paths.clear();

    emit pathChanged();
}


void DrawMapScene::setErasing(bool erasing)
{
    m_isErasing = erasing;
    QPen cursorPen = m_cursor->pen();
    if(erasing) {
        m_pen.setBrush(m_eraser);
        cursorPen.setColor(DRAWN_MAP_COLOR_CURSOR_ERASER);
    } else {
        m_pen.setBrush(m_brush);
        cursorPen.setColor(DRAWN_MAP_COLOR_CURSOR_PEN);
    }
    m_cursor->setPen(cursorPen);
}

QByteArray DrawMapScene::encode()
{
    QByteArray b(m_specialPoints);

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
    hideCursor();

    bool erasing = m_isErasing;

    oldItems.clear();
    oldPaths.clear();
    clear();
    paths.clear();
    m_specialPoints.clear();

    PathParams params;

    bool isSpecial = true;

    while(data.size() >= 5)
    {
        qint16 px = qFromBigEndian(*(qint16 *)data.data());
        data.remove(0, 2);
        qint16 py = qFromBigEndian(*(qint16 *)data.data());
        data.remove(0, 2);
        quint8 flags = *(quint8 *)data.data();
        data.remove(0, 1);
        //qDebug() << px << py;
        if(flags & 0x80)
        {
            isSpecial = false;

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
        } else
            if(isSpecial)
            {
                QPainterPath path;
                path.addEllipse(QPointF(px, py), 10, 10);

                addPath(path);

                qint16 x = qToBigEndian(px);
                qint16 y = qToBigEndian(py);
                m_specialPoints.append((const char *)&x, 2);
                m_specialPoints.append((const char *)&y, 2);
                m_specialPoints.append((const char *)&flags, 1);
            }

        if(!isSpecial)
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
        if( ((i != points.size() - 1) || (prevPoint == points[i]))
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

void DrawMapScene::setPathType(PathType pathType)
{
    m_pathType = pathType;
}

QList<QPointF> DrawMapScene::makeEllipse(const QPointF &center, const QPointF &corner)
{
    QList<QPointF> l;
    qreal rx = qAbs(center.x() - corner.x());
    qreal ry = qAbs(center.y() - corner.y());
    qreal r = qMax(rx, ry);

    if(r < 4)
    {
        l.append(center);
    } else
    {
        qreal angleDelta = qMax(static_cast<qreal> (0.1), qMin(static_cast<qreal> (0.7), 120 / r));
        for(qreal angle = 0.0; angle < 2*M_PI; angle += angleDelta)
            l.append(center + QPointF(rx * cos(angle), ry * sin(angle)));
        l.append(l.first());
    }

    return l;
}

QPointF DrawMapScene::putSomeConstraints(const QPointF &initialPoint, const QPointF &point)
{
    QPointF vector = point - initialPoint;

    for(int angle = 0; angle < 180; angle += 15)
    {
        QTransform transform;
        transform.rotate(angle);

        QPointF rotated = transform.map(vector);

        if(rotated.x() == 0) return point;
        if(qAbs(rotated.y() / rotated.x()) < 0.05) return initialPoint + transform.inverted().map(QPointF(rotated.x(), 0));
    }

    return point;
}

void DrawMapScene::optimize()
{
    if(!paths.size()) return;

    // break paths into segments
    Paths pth;

    foreach(const PathParams & pp, paths)
    {
        int l = pp.points.size();

        if(l == 1)
        {
            pth.prepend(pp);
        } else
        {
            for(int i = l - 2; i >= 0; --i)
            {
                PathParams p = pp;
                p.points = QList<QPoint>() << p.points[i] << p.points[i + 1];
                pth.prepend(pp);
            }
        }
    }

    // clear the scene
    oldItems.clear();
    oldPaths.clear();
    clear();
    paths.clear();
    m_specialPoints.clear();

    // render the result
    foreach(const PathParams & p, pth)
    {
        if(p.erasing)
            m_pen.setBrush(m_eraser);
        else
            m_pen.setBrush(m_brush);

        m_pen.setWidth(deserializePenWidth(p.width));

        addPath(pointsToPath(p.points), m_pen);
    }

    emit pathChanged();
}
