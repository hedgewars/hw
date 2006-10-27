/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Ulyanov Igor <iulyanov@gmail.com>
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

#ifndef _HEDGEHOGER_WIDGET
#define _HEDGEHOGER_WIDGET

#include <QWidget>

class FrameTeams;

class CHedgehogerWidget : public QWidget
{
  Q_OBJECT

 public:
  CHedgehogerWidget(QWidget * parent);
  ~CHedgehogerWidget();
  unsigned char getHedgehogsNum() const;

 protected:
  virtual void paintEvent(QPaintEvent* event);
  virtual void mousePressEvent ( QMouseEvent * event );
  
 private:
  CHedgehogerWidget();
  unsigned char numHedgehogs;
  FrameTeams* pOurFrameTeams;
};

#endif // _HEDGEHOGER_WIDGET
