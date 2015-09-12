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

#include <QGridLayout>
#include <QPushButton>
#include <QFileDialog>
#include <QCheckBox>
#include <QRadioButton>

#include "pagedrawmap.h"
#include "drawmapwidget.h"


QLayout * PageDrawMap::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    cbEraser = new QCheckBox(tr("Eraser"), this);
    pageLayout->addWidget(cbEraser, 0, 0);
    pbUndo = addButton(tr("Undo"), pageLayout, 1, 0);

    rbPolyline = new QRadioButton(tr("Polyline"), this);
    pageLayout->addWidget(rbPolyline, 2, 0);
    rbRectangle = new QRadioButton(tr("Rectangle"), this);
    pageLayout->addWidget(rbRectangle, 3, 0);
    rbEllipse = new QRadioButton(tr("Ellipse"), this);
    pageLayout->addWidget(rbEllipse, 4, 0);

    rbPolyline->setChecked(true);

    pbClear = addButton(tr("Clear"), pageLayout, 5, 0);
    pbOptimize = addButton(tr("Optimize"), pageLayout, 6, 0);
    pbOptimize->setVisible(false);
    pbLoad = addButton(tr("Load"), pageLayout, 7, 0);
    pbSave = addButton(tr("Save"), pageLayout, 8, 0);

    drawMapWidget = new DrawMapWidget(this);
    pageLayout->addWidget(drawMapWidget, 0, 1, 10, 1);

    return pageLayout;
}

void PageDrawMap::connectSignals()
{
    connect(cbEraser, SIGNAL(toggled(bool)), drawMapWidget, SLOT(setErasing(bool)));
    connect(pbUndo, SIGNAL(clicked()), drawMapWidget, SLOT(undo()));
    connect(pbClear, SIGNAL(clicked()), drawMapWidget, SLOT(clear()));
    connect(pbOptimize, SIGNAL(clicked()), drawMapWidget, SLOT(optimize()));
    connect(pbLoad, SIGNAL(clicked()), this, SLOT(load()));
    connect(pbSave, SIGNAL(clicked()), this, SLOT(save()));

    connect(rbPolyline, SIGNAL(toggled(bool)), this, SLOT(pathTypeSwitched(bool)));
    connect(rbRectangle, SIGNAL(toggled(bool)), this, SLOT(pathTypeSwitched(bool)));
    connect(rbEllipse, SIGNAL(toggled(bool)), this, SLOT(pathTypeSwitched(bool)));
}

PageDrawMap::PageDrawMap(QWidget* parent) : AbstractPage(parent)
{
    initPage();
}

void PageDrawMap::load()
{
    QString fileName = QFileDialog::getOpenFileName(NULL, tr("Load drawn map"), ".", tr("Drawn Maps") + " (*.hwmap);;" + tr("All files") + " (*)");

    if(!fileName.isEmpty())
        drawMapWidget->load(fileName);
}

void PageDrawMap::save()
{
    QString fileName = QFileDialog::getSaveFileName(NULL, tr("Save drawn map"), "./map.hwmap", tr("Drawn Maps") + " (*.hwmap);;" + tr("All files") + " (*)");

    if(!fileName.isEmpty())
        drawMapWidget->save(fileName);
}

void PageDrawMap::pathTypeSwitched(bool b)
{
    if(b)
    {
        if(rbPolyline->isChecked()) drawMapWidget->setPathType(DrawMapScene::Polyline);
        else if(rbRectangle->isChecked()) drawMapWidget->setPathType(DrawMapScene::Rectangle);
        else if(rbEllipse->isChecked()) drawMapWidget->setPathType(DrawMapScene::Ellipse);
    }
}
