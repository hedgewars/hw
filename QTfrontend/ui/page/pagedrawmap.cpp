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
#include <QSpinBox>
#include <QDir>

#include "pagedrawmap.h"
#include "drawmapwidget.h"
#include "hwconsts.h"


QLayout * PageDrawMap::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    cbEraser = new QCheckBox(tr("Eraser"), this);
    pageLayout->addWidget(cbEraser, 0, 0);

    rbPolyline = new QRadioButton(tr("Polyline"), this);
    pageLayout->addWidget(rbPolyline, 1, 0);
    rbRectangle = new QRadioButton(tr("Rectangle"), this);
    pageLayout->addWidget(rbRectangle, 2, 0);
    rbEllipse = new QRadioButton(tr("Ellipse"), this);
    pageLayout->addWidget(rbEllipse, 3, 0);

    rbPolyline->setChecked(true);

    sbBrushSize = new QSpinBox(this);
    sbBrushSize->setWhatsThis(tr("Brush size"));
    sbBrushSize->setRange(DRAWN_MAP_BRUSH_SIZE_MIN, DRAWN_MAP_BRUSH_SIZE_MAX);
    sbBrushSize->setValue(DRAWN_MAP_BRUSH_SIZE_START);
    sbBrushSize->setSingleStep(DRAWN_MAP_BRUSH_SIZE_STEP);
    pageLayout->addWidget(sbBrushSize, 4, 0);

    pbUndo = addButton(tr("Undo"), pageLayout, 5, 0);
    pbClear = addButton(tr("Clear"), pageLayout, 6, 0);

    pbOptimize = addButton(tr("Optimize"), pageLayout, 7, 0);
    // The optimize button is quite buggy, so we disable it for now.
    // TODO: Re-enable optimize button when it's finished.
    pbOptimize->setVisible(false);

    drawMapWidget = new DrawMapWidget(this);
    pageLayout->addWidget(drawMapWidget, 0, 1, 10, 1);

    return pageLayout;
}

QLayout * PageDrawMap::footerLayoutDefinition()
{
    QHBoxLayout * bottomLayout = new QHBoxLayout();

    bottomLayout->addStretch();

    pbLoad = addButton(":/res/Load.png", bottomLayout, 0, true, Qt::AlignBottom);
    pbLoad ->setWhatsThis(tr("Load"));
    pbLoad->setStyleSheet("QPushButton{margin: 24px 0 0 0;}");

    pbSave = addButton(":/res/Save.png", bottomLayout, 0, true, Qt::AlignBottom);
    pbSave ->setWhatsThis(tr("Save"));
    pbSave->setStyleSheet("QPushButton{margin: 24px 0 0 0;}");

    return bottomLayout;
}

void PageDrawMap::connectSignals()
{
    connect(cbEraser, SIGNAL(toggled(bool)), drawMapWidget, SLOT(setErasing(bool)));
    connect(pbUndo, SIGNAL(clicked()), drawMapWidget, SLOT(undo()));
    connect(pbClear, SIGNAL(clicked()), drawMapWidget, SLOT(clear()));
    connect(pbOptimize, SIGNAL(clicked()), drawMapWidget, SLOT(optimize()));
    connect(sbBrushSize, SIGNAL(valueChanged(int)), drawMapWidget, SLOT(setBrushSize(int)));

    connect(drawMapWidget, SIGNAL(brushSizeChanged(int)), this, SLOT(brushSizeChanged(int)));

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
    QString loadDir = QDir(cfgdir->absolutePath() + "/DrawnMaps").absolutePath();
    QString fileName = QFileDialog::getOpenFileName(this, tr("Load drawn map"), loadDir, tr("Drawn Maps") + " (*.hwmap);;" + tr("All files") + " (*)");

    if(!fileName.isEmpty())
        drawMapWidget->load(fileName);
}

void PageDrawMap::save()
{
    QString saveDir = QDir(cfgdir->absolutePath() + "/DrawnMaps/map.hwmap").absolutePath();
    QString fileName = QFileDialog::getSaveFileName(this, tr("Save drawn map"), saveDir, tr("Drawn Maps") + " (*.hwmap);;" + tr("All files") + " (*)");

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

void PageDrawMap::brushSizeChanged(int brushSize)
{
    sbBrushSize->setValue(brushSize);
}
