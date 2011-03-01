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

#include <QFile>
#include <QMessageBox>

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
    switch (e->type()) {
    case QEvent::LanguageChange:
        ui->retranslateUi(this);
        break;
    default:
        break;
    }
}

void DrawMapWidget::setScene(DrawMapScene * scene)
{
    ui->graphicsView->setScene(scene);
    m_scene = scene;
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

void DrawMapWidget::save(const QString & fileName)
{
    if(m_scene)
    {
        QFile file(fileName);

        if(!file.open(QIODevice::WriteOnly))
            QMessageBox::warning(this, tr("File error"), tr("Cannot open file '%1' for writing").arg(fileName));
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
            QMessageBox::warning(this, tr("File error"), tr("Cannot read file '%1'").arg(fileName));
        else
            m_scene->decode(qUncompress(QByteArray::fromBase64(f.readAll())));
    }
}
