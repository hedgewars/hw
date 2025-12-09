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

#include "pagedrawmap.h"

#include <QCheckBox>
#include <QDir>
#include <QFileDialog>
#include <QGridLayout>
#include <QPushButton>
#include <QRadioButton>
#include <QSpinBox>

#include "drawmapwidget.h"
#include "hwconsts.h"

QLayout* PageDrawMap::bodyLayoutDefinition() {
  QGridLayout* pageLayout = new QGridLayout();

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

QLayout* PageDrawMap::footerLayoutDefinition() {
  QHBoxLayout* bottomLayout = new QHBoxLayout();

  bottomLayout->addStretch();

  pbLoad = addButton(QStringLiteral(":/res/Load.png"), bottomLayout, 0, true,
                     Qt::AlignBottom);
  pbLoad->setWhatsThis(tr("Load"));
  pbLoad->setStyleSheet(QStringLiteral("QPushButton{margin: 24px 0 0 0;}"));

  pbSave = addButton(QStringLiteral(":/res/Save.png"), bottomLayout, 0, true,
                     Qt::AlignBottom);
  pbSave->setWhatsThis(tr("Save"));
  pbSave->setStyleSheet(QStringLiteral("QPushButton{margin: 24px 0 0 0;}"));

  return bottomLayout;
}

void PageDrawMap::connectSignals() {
  connect(cbEraser, &QAbstractButton::toggled, drawMapWidget,
          &DrawMapWidget::setErasing);
  connect(pbUndo, &QAbstractButton::clicked, drawMapWidget,
          &DrawMapWidget::undo);
  connect(pbClear, &QAbstractButton::clicked, drawMapWidget,
          &DrawMapWidget::clear);
  connect(pbOptimize, &QAbstractButton::clicked, drawMapWidget,
          &DrawMapWidget::optimize);
  connect(sbBrushSize, &QSpinBox::valueChanged, drawMapWidget,
          &DrawMapWidget::setBrushSize);

  connect(drawMapWidget, &DrawMapWidget::brushSizeChanged, this,
          &PageDrawMap::brushSizeChanged);

  connect(pbLoad, &QAbstractButton::clicked, this, &PageDrawMap::load);
  connect(pbSave, &QAbstractButton::clicked, this, &PageDrawMap::save);

  connect(rbPolyline, &QAbstractButton::toggled, this,
          &PageDrawMap::pathTypeSwitched);
  connect(rbRectangle, &QAbstractButton::toggled, this,
          &PageDrawMap::pathTypeSwitched);
  connect(rbEllipse, &QAbstractButton::toggled, this,
          &PageDrawMap::pathTypeSwitched);
}

PageDrawMap::PageDrawMap(QWidget* parent) : AbstractPage(parent) { initPage(); }

void PageDrawMap::load() {
  QString loadDir =
      QDir(cfgdir.absolutePath() + QStringLiteral("/DrawnMaps")).absolutePath();
  QString fileName = QFileDialog::getOpenFileName(
      this, tr("Load drawn map"), loadDir,
      tr("Drawn Maps") + QStringLiteral(" (*.hwmap);;") + tr("All files") +
          QStringLiteral(" (*)"));

  if (!fileName.isEmpty()) drawMapWidget->load(fileName);
}

void PageDrawMap::save() {
  QString saveDir =
      QDir(cfgdir.absolutePath() + QStringLiteral("/DrawnMaps/map.hwmap"))
          .absolutePath();
  QString fileName = QFileDialog::getSaveFileName(
      this, tr("Save drawn map"), saveDir,
      tr("Drawn Maps") + QStringLiteral(" (*.hwmap);;") + tr("All files") +
          QStringLiteral(" (*)"));

  if (!fileName.isEmpty()) drawMapWidget->save(fileName);
}

void PageDrawMap::pathTypeSwitched(bool b) {
  if (b) {
    if (rbPolyline->isChecked())
      drawMapWidget->setPathType(DrawMapScene::Polyline);
    else if (rbRectangle->isChecked())
      drawMapWidget->setPathType(DrawMapScene::Rectangle);
    else if (rbEllipse->isChecked())
      drawMapWidget->setPathType(DrawMapScene::Ellipse);
  }
}

void PageDrawMap::brushSizeChanged(int brushSize) {
  sbBrushSize->setValue(brushSize);
}
