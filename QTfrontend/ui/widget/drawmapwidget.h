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

#ifndef DRAWMAPWIDGET_H
#define DRAWMAPWIDGET_H

#include <QWidget>
#include <QHBoxLayout>
#include <QPushButton>
#include <QGraphicsView>
#include <QLabel>
#include <QSizePolicy>

#include "drawmapscene.h"


class DrawMapView : public QGraphicsView
{
    Q_OBJECT

public:
    explicit DrawMapView(QWidget *parent = 0);
    ~DrawMapView();

    void setScene(DrawMapScene *scene);

protected:
    void enterEvent(QEvent * event);
    void leaveEvent(QEvent * event);
    bool viewportEvent(QEvent * event);

private:
    DrawMapScene * m_scene;
};

namespace Ui
{
    class Ui_DrawMapWidget
    {
        public:
            DrawMapView *graphicsView;
            QLabel * lblPoints;

            void setupUi(QWidget *drawMapWidget)
            {
                QVBoxLayout * vbox = new QVBoxLayout(drawMapWidget);
                vbox->setMargin(0);
                QLayout * arLayout = new QVBoxLayout();
                arLayout->setAlignment(Qt::AlignCenter);
                vbox->addLayout(arLayout);

                lblPoints = new QLabel("0", drawMapWidget);
                lblPoints->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Minimum);
                arLayout->addWidget(lblPoints);

                graphicsView = new DrawMapView(drawMapWidget);
                graphicsView->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
                graphicsView->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
                graphicsView->setRenderHint(QPainter::Antialiasing, true);
                graphicsView->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Maximum);
                arLayout->addWidget(graphicsView);

                retranslateUi(drawMapWidget);

                QMetaObject::connectSlotsByName(drawMapWidget);
            } // setupUi

            void retranslateUi(QWidget *drawMapWidget)
            {
                Q_UNUSED(drawMapWidget);
            } // retranslateUi

    };

    class DrawMapWidget: public Ui_DrawMapWidget {};
}

class DrawMapWidget : public QWidget
{
        Q_OBJECT

    public:
        explicit DrawMapWidget(QWidget *parent = 0);
        ~DrawMapWidget();

        void setScene(DrawMapScene * scene);

    public slots:
        void undo();
        void clear();
        void optimize();
        void setErasing(bool erasing);
        void save(const QString & fileName);
        void load(const QString & fileName);
        void setPathType(DrawMapScene::PathType pathType);

    protected:
        void changeEvent(QEvent *e);
        virtual void resizeEvent(QResizeEvent * event);
        virtual void showEvent(QShowEvent * event);

    private:
        Ui::DrawMapWidget *ui;

        DrawMapScene * m_scene;

    private slots:
        void pathChanged();
};

#endif // DRAWMAPWIDGET_H
