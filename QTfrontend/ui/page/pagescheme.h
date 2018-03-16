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

#ifndef PAGE_SCHEME_H
#define PAGE_SCHEME_H

#include "AbstractPage.h"
#include "togglebutton.h"

class FreqSpinBox;
class MinesTimeSpinBox;

class PageScheme : public AbstractPage
{
        Q_OBJECT

    public:
        PageScheme(QWidget* parent = 0);

        QPushButton * BtnCopy;
        QPushButton * BtnNew;
        QPushButton * BtnDelete;
        QComboBox * selectScheme;

        void setModel(QAbstractItemModel * model);

    public slots:
        void newRow();
        void copyRow();
        void deleteRow();

    protected:
        QLayout * bodyLayoutDefinition();
        QLayout * footerLayoutDefinition();
        void connectSignals();

    private:
        QDataWidgetMapper * mapper;
        ToggleButtonWidget * TBW_teamsDivide;
        ToggleButtonWidget * TBW_solid;
        ToggleButtonWidget * TBW_border;
        ToggleButtonWidget * TBW_lowGravity;
        ToggleButtonWidget * TBW_laserSight;
        ToggleButtonWidget * TBW_invulnerable;
        ToggleButtonWidget * TBW_resethealth;
        ToggleButtonWidget * TBW_vampiric;
        ToggleButtonWidget * TBW_karma;
        ToggleButtonWidget * TBW_artillery;
        ToggleButtonWidget * TBW_randomorder;
        ToggleButtonWidget * TBW_king;
        ToggleButtonWidget * TBW_placehog;
        ToggleButtonWidget * TBW_sharedammo;
        ToggleButtonWidget * TBW_disablegirders;
        ToggleButtonWidget * TBW_disablelandobjects;
        ToggleButtonWidget * TBW_aisurvival;
        ToggleButtonWidget * TBW_infattack;
        ToggleButtonWidget * TBW_resetweps;
        ToggleButtonWidget * TBW_perhogammo;
        ToggleButtonWidget * TBW_nowind;
        ToggleButtonWidget * TBW_morewind;
        ToggleButtonWidget * TBW_tagteam;
        ToggleButtonWidget * TBW_bottomborder;

        QSpinBox * SB_DamageModifier;
        QSpinBox * SB_TurnTime;
        QSpinBox * SB_InitHealth;
        QSpinBox * SB_SuddenDeath;
        QSpinBox * SB_WaterRise;
        QSpinBox * SB_HealthDecrease;
        FreqSpinBox * SB_CaseProb;
        QSpinBox * SB_HealthCrates;
        QSpinBox * SB_CrateHealth;
        MinesTimeSpinBox * SB_MinesTime;
        QSpinBox * SB_Mines;
        QSpinBox * SB_AirMines;
        QSpinBox * SB_MineDuds;
        QSpinBox * SB_Explosives;
        QSpinBox * SB_RopeModifier;
        QSpinBox * SB_GetAwayTime;
        QComboBox * CB_WorldEdge;
        QLineEdit * LE_name;
        QLabel * L_name;
        QLineEdit * LE_ScriptParam;

        QGroupBox * gbGameModes;
        QGroupBox * gbBasicSettings;

    private slots:
        void schemeSelected(int);
};

#endif
