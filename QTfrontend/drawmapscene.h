/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2011 Andrey Korotaev <unC0Rr@gmail.com>
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
    void clearMap();
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
