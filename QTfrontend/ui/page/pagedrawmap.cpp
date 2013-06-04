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

#include <QGridLayout>
#include <QPushButton>
#include <QFileDialog>
#include <QCheckBox>

#include "pagedrawmap.h"
#include "drawmapwidget.h"


QLayout * PageDrawMap::bodyLayoutDefinition()
{
    QGridLayout * pageLayout = new QGridLayout();

    cbEraser = new QCheckBox(tr("Eraser"), this);
    pageLayout->addWidget(cbEraser, 0, 0);
    pbUndo = addButton(tr("Undo"), pageLayout, 1, 0);
    pbClear = addButton(tr("Clear"), pageLayout, 2, 0);
    pbLoad = addButton(tr("Load"), pageLayout, 3, 0);
    pbSave = addButton(tr("Save"), pageLayout, 4, 0);

    drawMapWidget = new DrawMapWidget(this);
    pageLayout->addWidget(drawMapWidget, 0, 1, 6, 1);

    return pageLayout;
}

void PageDrawMap::connectSignals()
{
    connect(cbEraser, SIGNAL(toggled(bool)), drawMapWidget, SLOT(setErasing(bool)));
    connect(pbUndo, SIGNAL(clicked()), drawMapWidget, SLOT(undo()));
    connect(pbClear, SIGNAL(clicked()), drawMapWidget, SLOT(clear()));
    connect(pbLoad, SIGNAL(clicked()), this, SLOT(load()));
    connect(pbSave, SIGNAL(clicked()), this, SLOT(save()));
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
