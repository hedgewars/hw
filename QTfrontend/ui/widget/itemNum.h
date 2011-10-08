/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2011 Igor Ulyanov <iulyanov@gmail.com>
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

#include <QFrame>
#include <QImage>

#ifndef _ITEM_NUM_INCLUDED
#define _ITEM_NUM_INCLUDED

class ItemNum : public QFrame
{
  Q_OBJECT

  public:
    void setInfinityState(bool value);
    void setEnabled(bool value);
    unsigned char getItemsNum() const;
    void setItemsNum(const unsigned char num);

  private:
    QImage m_im;
    QImage m_img;
    bool infinityState;
    bool enabled;

  protected:
    ItemNum(const QImage& im, const QImage& img, QWidget * parent, unsigned char min=2, unsigned char max=8);
    virtual QSize sizeHint () const;
    virtual ~ItemNum()=0;

    bool nonInteractive;
    unsigned char minItems;
    unsigned char maxItems;
    unsigned char numItems;

    // from QWidget
    virtual void mousePressEvent ( QMouseEvent * event );
    virtual void paintEvent(QPaintEvent* event);

    // to be implemented in child
    virtual void incItems()=0;
    virtual void decItems()=0;
};

#endif // _ITEM_NUM_INCLUDED
