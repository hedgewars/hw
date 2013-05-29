/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QGraphicsEllipseItem>

class QGraphicsPathItem;

struct PathParams
{
    quint8 width;
    bool erasing;
    QList<QPoint> points;
};

typedef QList<PathParams> Paths;

class DrawMapScene : public QGraphicsScene
{
        Q_OBJECT
    public:
        explicit DrawMapScene(QObject *parent = 0);

        QByteArray encode();
        void decode(QByteArray data);
        int pointsCount();

    signals:
        void pathChanged();

    public slots:
        void undo();
        void clearMap();
        void simplifyLast();
        void setErasing(bool erasing);
        void showCursor();
        void hideCursor();

    private:
        QPen m_pen;
        QBrush m_eraser;
        QBrush m_brush;
        QGraphicsPathItem  * m_currPath;
        Paths paths;
        Paths oldPaths;
        bool m_isErasing;
        QList<QGraphicsItem *> oldItems;
        QGraphicsEllipseItem * m_cursor;
        bool m_isCursorShown;

        virtual void mouseMoveEvent(QGraphicsSceneMouseEvent * mouseEvent);
        virtual void mousePressEvent(QGraphicsSceneMouseEvent * mouseEvent);
        virtual void mouseReleaseEvent(QGraphicsSceneMouseEvent * mouseEvent);
        virtual void wheelEvent(QGraphicsSceneWheelEvent *);

        QPainterPath pointsToPath(const QList<QPoint> points);

        quint8 serializePenWidth(int width);
        int deserializePenWidth(quint8 width);
};

#endif // DRAWMAPSCENE_H
