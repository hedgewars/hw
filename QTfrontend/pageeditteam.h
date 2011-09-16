/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef PAGE_EDITTEAM_H
#define PAGE_EDITTEAM_H

#include "AbstractPage.h"
#include "binds.h"
#include "SDLs.h"

class SquareLabel;

class PageEditTeam : public AbstractPage
{
    Q_OBJECT

public:
    PageEditTeam(QWidget* parent, SDLInteraction * sdli);
    QSignalMapper* signalMapper1;
    QSignalMapper* signalMapper2;
    QGroupBox *GBoxHedgehogs;
    QGroupBox *GBoxTeam;
    QGroupBox *GBoxFort;
    QComboBox *CBFort;
    SquareLabel *FortPreview;
    QComboBox *CBGrave;
    QComboBox *CBFlag;
    QComboBox *CBTeamLvl;
    QComboBox *CBVoicepack;
    QGroupBox *GBoxBinds;
    QToolBox *BindsBox;
    QPushButton *BtnTeamDiscard;
    QPushButton *BtnTeamSave;
    QPushButton * BtnTestSound;
    QLineEdit * TeamNameEdit;
    QLineEdit * HHNameEdit[8];
    QComboBox * HHHats[8];
    QPushButton * randButton[8];
    QComboBox * CBBind[BINDS_NUMBER];
    QPushButton * randTeamButton;

private:
    SDLInteraction * mySdli;

public slots:
    void CBFort_activated(const QString & gravename);

private slots:
    void testSound();
    void fixHHname(int idx);
};

#endif

