/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Ulyanov Igor <iulyanov@gmail.com>
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

#include "hedgehogerWidget.h"

#include <QPainter>

#include "frameTeam.h"

CHedgehogerWidget::CHedgehogerWidget(const QImage& im, const QImage& img, QWidget * parent) :
    ItemNum(im, img, parent, 1)
{
    // TODO: maxHedgehogsPerGame doesn't reset properly and won't match map limits for now
    /*if(parent) {
      pOurFrameTeams = dynamic_cast<FrameTeams*>(parent->parentWidget());
    }
    if(pOurFrameTeams->overallHedgehogs + 4 > pOurFrameTeams->maxHedgehogsPerGame) {
      numItems = pOurFrameTeams->maxHedgehogsPerGame - pOurFrameTeams->overallHedgehogs;
    } else numItems = 4;
    pOurFrameTeams->overallHedgehogs += numItems;*/

    this->setMinimumWidth(20);
}

void CHedgehogerWidget::incItems()
{
    //if (pOurFrameTeams->overallHedgehogs < pOurFrameTeams->maxHedgehogsPerGame) {
    numItems++;
    //pOurFrameTeams->overallHedgehogs++;
    emit hedgehogsNumChanged();
    //}
}

void CHedgehogerWidget::decItems()
{
    numItems--;
    //pOurFrameTeams->overallHedgehogs--;
    emit hedgehogsNumChanged();
}

CHedgehogerWidget::~CHedgehogerWidget()
{
    // TODO: not called?
    //pOurFrameTeams->overallHedgehogs-=numItems;
}

void CHedgehogerWidget::setNonInteractive()
{
    nonInteractive=true;
}

void CHedgehogerWidget::setHHNum(unsigned int num)
{
    /*unsigned int diff = num - numItems;
    numItems += diff;
    pOurFrameTeams->overallHedgehogs += diff;*/
    numItems = num;
    repaint();
}

unsigned char CHedgehogerWidget::getHedgehogsNum() const
{
    return numItems;
}

void CHedgehogerWidget::paintEvent(QPaintEvent* event)
{
    Q_UNUSED(event);

    if (this->width() >= 11 * numItems + 28)
        ItemNum::paintEvent(event);

    QPainter painter(this);
    const QFont font("MS Shell Dlg", 12);
    painter.setFont(font);
    painter.drawText(this->width() - 14, 24, QString::number(numItems));

}
