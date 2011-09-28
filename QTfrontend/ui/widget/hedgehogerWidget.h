/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Ulyanov Igor <iulyanov@gmail.com>
 * Copyright (c) 2007-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "itemNum.h"

class FrameTeams;

class CHedgehogerWidget : public ItemNum
{
  Q_OBJECT

 public:
  CHedgehogerWidget(const QImage& im, const QImage& img, QWidget * parent);
  virtual ~CHedgehogerWidget();
  unsigned char getHedgehogsNum() const;
  void setHHNum (unsigned int num);
  void setNonInteractive();

 signals:
  void hedgehogsNumChanged();

 protected:
  virtual void incItems();
  virtual void decItems();

 private:
  CHedgehogerWidget();
  FrameTeams* pOurFrameTeams;
};

#endif // _HEDGEHOGER_WIDGET
