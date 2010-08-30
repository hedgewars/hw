/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef STATSPAGE_H
#define STATSPAGE_H

#include <QVector>
#include <QMap>
#include <QGraphicsView>
#include "pages.h"

class FitGraphicsView : public QGraphicsView
{
    Q_OBJECT

public:
    FitGraphicsView(QWidget* parent = 0);

protected:
    void resizeEvent(QResizeEvent * event);
};

class PageGameStats : public AbstractPage
{
    Q_OBJECT

public:
    PageGameStats(QWidget* parent = 0);

    QPushButton *BtnBack;
    QLabel *labelGameStats;
    QLabel *labelGameWin;
    QLabel *labelGameRank;
    FitGraphicsView * graphic;

public slots:
    void GameStats(char type, const QString & info);
    void clear();
    void renderStats();

private:
    void AddStatText(const QString & msg);

    QMap<quint32, QVector<quint32> > healthPoints;
    unsigned int playerPosition;
    quint32 lastColor;
};

#endif // STATSPAGE_H
