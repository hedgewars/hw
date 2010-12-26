/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006, 2007 Igor Ulyanov <iulyanov@gmail.com>
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

#ifndef _HWMAP_CONTAINER_INCLUDED
#define _HWMAP_CONTAINER_INCLUDED

#include <QWidget>
#include <QGridLayout>
#include <QComboBox>
#include <QLabel>
#include <QByteArray>
#include <QLineEdit>

#include "hwmap.h"
#include "drawmapscene.h"

class QPushButton;
class IconedGroupBox;
class QListWidget;

class MapFileErrorException
{
};

class HWMapContainer : public QWidget
{
  Q_OBJECT

 public:
  HWMapContainer(QWidget * parent=0);
  QString getCurrentSeed() const;
  QString getCurrentMap() const;
  QString getCurrentTheme() const;
  int     getCurrentHHLimit() const;
  QString getCurrentScheme() const;
  QString getCurrentWeapons() const;
  quint32 getTemplateFilter() const;
  MapGenerator get_mapgen(void) const;
  int get_maze_size(void) const;
  bool getCurrentIsMission() const;
  QByteArray getDrawnMapData();
  DrawMapScene * getDrawMapScene();
  void mapDrawingFinished();

 public slots:
  void askForGeneratedPreview();
  void setSeed(const QString & seed);
  void setMap(const QString & map);
  void setTheme(const QString & theme);
  void setTemplateFilter(int);
  void setMapgen(MapGenerator m);
  void setMaze_size(int size);
  void setDrawnMapData(const QByteArray & ar);

 signals:
  void seedChanged(const QString & seed);
  void mapChanged(const QString & map);
  void themeChanged(const QString & theme);
  void newTemplateFilter(int filter);
  void mapgenChanged(MapGenerator m);
  void maze_sizeChanged(int s);
  void drawMapRequested();
  void drawnMapChanged(const QByteArray & data);

 private slots:
  void setImage(const QImage newImage);
  void setHHLimit(int hhLimit);
  void mapChanged(int index);
  void setRandomSeed();
  void setRandomTheme();
  void setRandomMap();
  void setRandomStatic();
  void setRandomMission();
  void themeSelected(int currentRow);
  void addInfoToPreview(QPixmap image);
  void templateFilterChanged(int filter);
  void seedEdited();

 protected:
  virtual void resizeEvent ( QResizeEvent * event );

 private:
  QGridLayout mainLayout;
  QPushButton* imageButt;
  QComboBox* chooseMap;
  IconedGroupBox* gbThemes;
  QListWidget* lwThemes;
  HWMap* pMap;
  QString m_seed;
  QLineEdit* seedEdit;
  QPushButton* seedSet;
  QLabel* seedLabel;
  int hhLimit;
  int templateFilter;
  QPixmap hhSmall;
  QLabel* lblFilter;
  QComboBox* CB_TemplateFilter;
  QLabel *maze_size_label;
  QComboBox *maze_size_selection;
  MapGenerator mapgen;
  int numMissions;
  DrawMapScene drawMapScene;

  void updatePreview();
};

#endif // _HWMAP_CONTAINER_INCLUDED
