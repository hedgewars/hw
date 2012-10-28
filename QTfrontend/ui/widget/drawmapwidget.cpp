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

#include <QFile>
#include <QMessageBox>
#include <QEvent>
#include <QDebug>

#include "drawmapwidget.h"

DrawMapWidget::DrawMapWidget(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::DrawMapWidget)
{
    ui->setupUi(this);

    m_scene = 0;
}

DrawMapWidget::~DrawMapWidget()
{
    delete ui;
}

void DrawMapWidget::changeEvent(QEvent *e)
{
    QWidget::changeEvent(e);
    switch (e->type())
    {
        case QEvent::LanguageChange:
            ui->retranslateUi(this);
            break;
        default:
            break;
    }
}

void DrawMapWidget::setScene(DrawMapScene * scene)
{
    m_scene = scene;

    ui->graphicsView->setScene(scene);
    connect(scene, SIGNAL(pathChanged()), this, SLOT(pathChanged()));
}

void DrawMapWidget::resizeEvent(QResizeEvent * event)
{
    Q_UNUSED(event);

    if(ui->graphicsView && ui->graphicsView->scene())
        ui->graphicsView->fitInView(ui->graphicsView->scene()->sceneRect(), Qt::KeepAspectRatio);
}

void DrawMapWidget::showEvent(QShowEvent * event)
{
    Q_UNUSED(event);

    resizeEvent(0);
}

void DrawMapWidget::undo()
{
    if(m_scene) m_scene->undo();
}

void DrawMapWidget::clear()
{
    if(m_scene) m_scene->clearMap();
}

void DrawMapWidget::setErasing(bool erasing)
{
    if(m_scene) m_scene->setErasing(erasing);
}

void DrawMapWidget::save(const QString & fileName)
{
    if(m_scene)
    {
        QFile file(fileName);

        if(!file.open(QIODevice::WriteOnly))
        {
            QMessageBox errorMsg(this);
            errorMsg.setIcon(QMessageBox::Warning);
            errorMsg.setWindowTitle(QMessageBox::tr("File error"));
            errorMsg.setText(QMessageBox::tr("Cannot open '%1' for writing").arg(fileName));
            errorMsg.setWindowModality(Qt::WindowModal);
            errorMsg.exec();
        }
        else
            file.write(qCompress(m_scene->encode()).toBase64());
    }
}

void DrawMapWidget::load(const QString & fileName)
{
    if(m_scene)
    {
        QFile f(fileName);

        if(!f.open(QIODevice::ReadOnly))
        {
            QMessageBox errorMsg(this);
            errorMsg.setIcon(QMessageBox::Warning);
            errorMsg.setWindowTitle(QMessageBox::tr("File error"));
            errorMsg.setText(QMessageBox::tr("Cannot open '%1' for reading").arg(fileName));
            errorMsg.setWindowModality(Qt::WindowModal);
            errorMsg.exec();
        }
        else
            m_scene->decode(qUncompress(QByteArray::fromBase64(f.readAll())));
    }
}

void DrawMapWidget::pathChanged()
{
    ui->lblPoints->setNum(m_scene->pointsCount());
}



DrawMapView::DrawMapView(QWidget *parent) :
    QGraphicsView(parent)
{
   setMouseTracking(true);

    m_scene = 0;
}


DrawMapView::~DrawMapView()
{

}

void DrawMapView::setScene(DrawMapScene *scene)
{
    m_scene = scene;

    QGraphicsView::setScene(scene);
}

// Why don't I ever recieve this event?
void DrawMapView::enterEvent(QEvent *event)
{
    if(m_scene)
        m_scene->showCursor();

    QGraphicsView::enterEvent(event);
}

void DrawMapView::leaveEvent(QEvent *event)
{
    if(m_scene)
        m_scene->hideCursor();

    QGraphicsView::leaveEvent(event);
}

bool DrawMapView::viewportEvent(QEvent *event)
{
    return QGraphicsView::viewportEvent(event);
}
