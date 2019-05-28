/*
 * Hedgewars, a free turn based strategy game
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

#ifndef STATSPAGE_H
#define STATSPAGE_H

#include <QVector>
#include <QMap>
#include <QGraphicsView>

#include "AbstractPage.h"

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

        QPushButton *btnSave;
        QPushButton *btnRestart;
        QLabel *mainNote;
        QLabel *labelGameStats;
        QLabel *labelGameWin;
        QLabel *labelGameRank;
        QLabel *labelGraphTitle;
        QString kindOfPoints;
        FitGraphicsView * graphic;

    public slots:
        void GameStats(char type, const QString & info);
        void clear();
        void renderStats();
        void restartBtnVisible(bool visible);

    signals:
        void saveDemoRequested();
        void restartGameRequested();

    private:
        void AddStatText(const QString & msg);
        void applySpacing();

        QMap<qint32, QVector<qint32> > healthPoints;
        unsigned int playerPosition;
        unsigned int scriptPlayerPosition;
        quint32 lastColor;
        bool defaultGraphTitle;
        QScopedPointer<QGraphicsScene> m_scene;

        QLabel* labelDetails;
        QGroupBox* gbDetails;
        QGroupBox* gbRanks;
        QGridLayout* pageLayout;

    protected:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();
};

#endif // STATSPAGE_H
