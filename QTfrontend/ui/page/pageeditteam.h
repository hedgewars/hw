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

#ifndef PAGE_EDITTEAM_H
#define PAGE_EDITTEAM_H

#include "AbstractPage.h"
#include "binds.h"
#include "hwconsts.h"
#include "namegen.h"
#include "SDLInteraction.h"

#include "team.h"

class SquareLabel;
class KeyBinder;
class HatButton;

class PageEditTeam : public AbstractPage
{
        Q_OBJECT

    public:
        PageEditTeam(QWidget* parent);

        void createTeam(const QString & name, const QString & playerHash);
        void editTeam(const QString & name, const QString & playerHash);
        void deleteTeam(const QString & name);

    public slots:
        void CBTeamLvl_activated(const int index);
        void CBFort_activated(const int index);

    private:
        QTabWidget * tbw;
        QSignalMapper* signalMapper1;
        QSignalMapper* signalMapper2;
        QGroupBox *GBoxHedgehogs;
        QGroupBox *GBoxTeam;
        QGroupBox *GBoxFort;
        QComboBox *CBFort;
        SquareLabel *FortPreview;
        QComboBox *CBGrave;
        QComboBox *CBFlag;
        QLabel *CPUFlag;
        QLabel *CPUFlagLabel;
        QWidget *hboxCPUWidget;
        QPixmap pixCPU[5];
        QComboBox *CBTeamLvl;
        QComboBox *CBVoicepack;
        QGroupBox *GBoxBinds;
        QToolBox *BindsBox;
        QLineEdit * TeamNameEdit;
        QLineEdit * HHNameEdit[HEDGEHOGS_PER_TEAM];
        HatButton * HHHats[HEDGEHOGS_PER_TEAM];
        HWTeam data();
        QString m_playerHash;
        QString OldTeamName;
        KeyBinder * binder;
        bool m_loaded;

        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

        void loadTeam(const HWTeam & team);

        // page 1
        QPushButton * btnRandomTeam;
        QPushButton * btnRandomNames;
        QPushButton * btnRandomHats;

        QPushButton * btnRandomHogName[HEDGEHOGS_PER_TEAM];
        QPushButton * btnRandomTeamName;
        QPushButton * btnRandomGrave;
        QPushButton * btnRandomFlag;
        QPushButton * btnRandomVoice;
        QPushButton * btnRandomFort;
        QPushButton * btnTestSound;

        void lazyLoad();

    private slots:
        void saveTeam();
        void setRandomTeam();
        void setRandomHogNames();
        void setRandomHats();

        void setRandomTeamName();
        void setRandomGrave();
        void setRandomFlag();
        void setRandomVoice();
        void setRandomFort();

        void setRandomHogName(int hh_index);

        /// Plays a random voice sound of the currently edited team.
        void testSound();

        void fixHHname(int idx);
        void resetAllBinds();
};

#endif

