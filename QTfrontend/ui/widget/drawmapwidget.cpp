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
    connect(scene, SIGNAL(brushSizeChanged(int)), this, SLOT(brushSizeChanged_slot(int)));
}

void DrawMapWidget::resizeEvent(QResizeEvent * event)
{
    Q_UNUSED(event);

	if(!m_scene)
		return;
		
    int height = this->height();
    int width = this->width();

    if ((m_scene->height() > 0) && (m_scene->width() > 0) && (height > 0))
    {
        qreal saspect = m_scene->width() / m_scene->height();

        qreal h = height;
        qreal w = width;
        qreal waspect = w / h;

        if (waspect < saspect)
        {
            h = w / saspect;
        }
        else if (waspect > saspect)
        {
            w = saspect * h;
        }

        int fixedh = (int)h;
        int fixedw = (int)w;

        if (ui->graphicsView->width() != fixedw)
        {
            ui->graphicsView->setFixedWidth(fixedw);
        }

        if (ui->graphicsView->height() != fixedh)
        {
            ui->graphicsView->setFixedHeight(fixedh);
        }

    }

    if(ui->graphicsView && ui->graphicsView->scene())
        ui->graphicsView->fitInView(m_scene->sceneRect(), Qt::KeepAspectRatio);
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

void DrawMapWidget::optimize()
{
    if(m_scene) m_scene->optimize();
}

void DrawMapWidget::setErasing(bool erasing)
{
    if(m_scene) m_scene->setErasing(erasing);
}

void DrawMapWidget::setPathType(DrawMapScene::PathType pathType)
{
    if(m_scene) m_scene->setPathType(pathType);
}

void DrawMapWidget::setBrushSize(int brushSize)
{
    if(m_scene) m_scene->setBrushSize(brushSize);
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
            //m_scene->decode(f.readAll());
    }
}

void DrawMapWidget::pathChanged()
{
    ui->lblPoints->setNum(m_scene->pointsCount());
}

void DrawMapWidget::brushSizeChanged_slot(int brushSize)
{
    emit brushSizeChanged(brushSize);
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

// Why don't I ever receive this event?
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
