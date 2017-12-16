/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Ulyanov Igor <iulyanov@gmail.com>
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

    this->setMinimumWidth(48);
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

    if ((this->width() >= 11 * numItems + 26) || (numItems == 1))
        ItemNum::paintEvent(event);
    else
    {
        int width = this->width() - 38;
        QPainter painter(this);

        for(int i=0; i<numItems; i++)
        {
            QRect target((i * width) / (numItems -1), i % 2, 25, 35);
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

    QPainter painter(this);
    painter.setFont(QFont("MS Shell Dlg", 10, QFont::Bold));
    painter.drawText(this->width() - 12, 23, QString::number(numItems));

}
