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

#ifndef BGWIDGET_H
#define BGWIDGET_H

#include <QWidget>
//#include <QGLWidget>
#include <QPainter>
#include <QTimer>
#include <QPaintEvent>
#include <QTime>
#include <QPoint>

#define SPRITE_MAX 12

#define ANIMATION_INTERVAL 40

class SpritePosition
{
public:
    SpritePosition(QWidget * parent, int sh);
    ~SpritePosition();
private:
    float fX;
    float fY;
    float fXMov;
    float fYMov;
    int iAngle;
    QWidget * wParent;
    int iSpriteHeight;
public:
    void move();
    void reset();
    QPoint pos();
    int getAngle();
    void init();
};

class BGWidget : public QWidget
{
    Q_OBJECT
public:
    BGWidget(QWidget * parent);
    ~BGWidget();
    void startAnimation();
    void stopAnimation();
    void init();
private:
    QImage sprite;
    QTimer * timerAnimation;
    SpritePosition * spritePositions[SPRITE_MAX];
    QImage * rotatedSprites[360];
protected:
    void paintEvent(QPaintEvent * event);
private slots:
    void animate();
};

#endif // BGWIDGET_H
