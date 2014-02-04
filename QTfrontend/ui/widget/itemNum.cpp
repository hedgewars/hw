/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2012 Igor Ulyanov <iulyanov@gmail.com>
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

#include "itemNum.h"
#include "hwform.h"

#include <QMouseEvent>
#include <QPainter>

ItemNum::ItemNum(const QImage& im, const QImage& img, QWidget * parent, unsigned char min, unsigned char max) :
    QFrame(parent), m_im(im), m_img(img), infinityState(false), nonInteractive(false), minItems(min), maxItems(max),
    numItems(min+2 >= max ? min : min+2)
{
    enabled = true;
    //if(frontendEffects) setAttribute(Qt::WA_PaintOnScreen, true);
}

ItemNum::~ItemNum()
{
}

void ItemNum::mousePressEvent ( QMouseEvent * event )
{
    if(nonInteractive) return;
    if(event->button()==Qt::LeftButton && enabled)
    {
        event->accept();
        if((infinityState && numItems <= maxItems) || (!infinityState && numItems < maxItems))
        {
            incItems();
        }
        else
        {
            numItems = minItems+1;
            // appears there's an emit in there
            decItems();
        }
    }
    else if (event->button()==Qt::RightButton && enabled)
    {
        event->accept();
        if(numItems > minItems)
        {
            decItems();
        }
        else
        {
            numItems = maxItems+(infinityState?0:-1);
            incItems();
        }
    }
    else
    {
        event->ignore();
        return;
    }
    repaint();
}
void ItemNum::wheelEvent ( QWheelEvent * event )
{
    if (nonInteractive) return;
    if (!enabled)
    {
        event->ignore();
        return;
    }
    event->accept();

    bool up = (event->delta() > 0); // positive delta is up, negative is down

    // negative delta on horizontal wheel is not left, but right
    if (event->orientation() == Qt::Horizontal)
        up = !up;

    if(up)
    {
        if((infinityState && numItems <= maxItems) || (!infinityState && numItems < maxItems))
            incItems();
    }
    else
    {
        if(numItems > minItems)
            decItems();
    }
    repaint();
}

QSize ItemNum::sizeHint () const
{
    return QSize((maxItems+1)*12, 32);
}

void ItemNum::paintEvent(QPaintEvent* event)
{
    Q_UNUSED(event);

    QPainter painter(this);

    if (numItems==maxItems+1)
    {
        QRect target(0, 0, 100, 32);
        if (enabled)
        {
            painter.drawImage(target, QImage(":/res/infinity.png"));
        }
        else
        {
            painter.drawImage(target, QImage(":/res/infinitygrey.png"));
        }
    }
    else
    {
        for(int i=0; i<numItems; i++)
        {
            QRect target(11 * i, i % 2, 25, 35);
            if (enabled)
            {
                painter.drawImage(target, m_im);
            }
            else
            {
                painter.drawImage(target, m_img);
            }
        }
    }
}

unsigned char ItemNum::getItemsNum() const
{
    return numItems;
}

void ItemNum::setItemsNum(const unsigned char num)
{
    numItems=num;
    repaint();
}

void ItemNum::setInfinityState(bool value)
{
    infinityState=value;
}

void ItemNum::setEnabled(bool value)
{
    enabled=value;
    repaint();
}
