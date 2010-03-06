/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2009 Kristian Lehmann <email@thexception.net>
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

#include "bgwidget.h"

SpritePosition::SpritePosition(QWidget * parent, int sh)
{
    wParent = parent;
    iSpriteHeight = sh;
    reset();
}

SpritePosition::~SpritePosition()
{
}

void SpritePosition::move()
{
    fX += fXMov;
    fY += fYMov;
    iAngle += 4;
    if (iAngle >= 360) iAngle = 0;
    if (fY > wParent->height()) reset();
}

void SpritePosition::reset()
{
    fY = -1 * iSpriteHeight;
    fX = (qrand() % ((int)(wParent->width() * 1.5))) - wParent->width()/2;
    fYMov = ((qrand() % 400)+300) / 100.0f;
    fXMov = fYMov * 0.5f;
    iAngle = qrand() % 360;
}

QPoint SpritePosition::pos()
{
    return QPoint((int)fX,(int)fY);
}

int SpritePosition::getAngle()
{
    return iAngle;
}

void SpritePosition::init()
{
    fY = qrand() % (wParent->height() + 1);
    fX = qrand() % (wParent->width() + 1);
}

BGWidget::BGWidget(QWidget * parent) : QWidget(parent)
{
    setAttribute(Qt::WA_NoSystemBackground, true);
    sprite.load(":/res/Star.png");

    setAutoFillBackground(false);

    for (int i = 0; i < SPRITE_MAX; i++) spritePositions[i] = new SpritePosition(this, sprite.height());

    for (int i = 0; i < 360; i++)
    {
        rotatedSprites[i] = new QImage(sprite.width(), sprite.height(), QImage::Format_ARGB32);
        rotatedSprites[i]->fill(0);

        QPoint translate(sprite.width()/2, sprite.height()/2);

        QPainter p;
        p.begin(rotatedSprites[i]);
    //  p.setRenderHint(QPainter::Antialiasing);
        p.setRenderHint(QPainter::SmoothPixmapTransform);
        p.translate(translate.x(), translate.y());
        p.rotate(i);
        p.translate(-1*translate.x(), -1*translate.y());
        p.drawImage(0, 0, sprite);
    }

    timerAnimation = new QTimer();
    connect(timerAnimation, SIGNAL(timeout()), this, SLOT(animate()));
    timerAnimation->setInterval(ANIMATION_INTERVAL);
}

BGWidget::~BGWidget()
{
    for (int i = 0; i < SPRITE_MAX; i++) delete spritePositions[i];
    for (int i = 0; i < 360; i++) delete rotatedSprites[i];
    delete timerAnimation;
}

void BGWidget::paintEvent(QPaintEvent *event)
{
    QPainter p;
    p.begin(this);
    //p.setRenderHint(QPainter::Antialiasing);
    for (int i = 0; i < SPRITE_MAX; i++)
    {
        QPoint point = spritePositions[i]->pos();
        p.drawImage(point.x(), point.y(), *rotatedSprites[spritePositions[i]->getAngle()]);
    }
    p.end();
}

void BGWidget::animate()
{
    for (int i = 0; i < SPRITE_MAX; i++)
    {
        // bottom edge of star *seems* clipped, but in fact, if I switch to just plain old repaint()/update() it is still clipped - artifact of transform?  As for 5, is arbitrary number. 4 was noticeably clipping, 5 seemed same as update() - I assume extra room is due to rotation and value really should be calculated proportional to width/height
        update(spritePositions[i]->pos().x(),spritePositions[i]->pos().y(), sprite.width()+5, sprite.height()+5);
        spritePositions[i]->move();
    }
}

void BGWidget::startAnimation()
{
    timerAnimation->start();
}

void BGWidget::stopAnimation()
{
    timerAnimation->stop();
}

void BGWidget::init()
{
    for (int i = 0; i < SPRITE_MAX; i++) spritePositions[i]->init();
}
