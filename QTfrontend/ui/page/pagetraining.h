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

#ifndef PAGE_TRAINING_H
#define PAGE_TRAINING_H

#include "AbstractPage.h"

class PageTraining : public AbstractPage
{
        Q_OBJECT

    public:
        PageTraining(QWidget* parent = 0);
        QListWidget * lstTrainings;
        QListWidget * lstChallenges;
        QListWidget * lstScenarios;
        QPushButton * btnPreview;
        QPushButton * btnStart;
        QComboBox * CBTeam;

    public slots:
        void updateInfo();

    signals:
        void startMission(const QString & scriptName, const QString & subFolder);


    protected:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();


    private:
        QLabel * lblCaption;
        QLabel * lblDescription;
        QLabel * lblHighscores;
        QTabWidget * tbw;
        QSettings * m_info;
        QString getSubFolderOfSelected();


    private slots:
        void startSelected();

};

#endif

