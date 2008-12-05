/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006, 2007 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef GAMECONFIGWIDGET_H
#define GAMECONFIGWIDGET_H

#include <QWidget>
#include <QStringList>
#include <QGroupBox>

#include "mapContainer.h"

class QCheckBox;
class QVBoxLayout;
class QSpinBox;
class QLabel;

class GameCFGWidget : public QGroupBox
{
	Q_OBJECT

public:
	GameCFGWidget(QWidget* parent, bool externalControl=false);
	quint32 getGameFlags() const;
	QString getCurrentSeed() const;
	QString getCurrentMap() const;
	QString getCurrentTheme() const;
	quint32 getInitHealth() const;
	quint32 getTurnTime() const;
	QStringList getFullConfig() const;

	QComboBox* WeaponsName;

public slots:
	void setSeed(const QString & seed);
	void setMap(const QString & map);
	void setTheme(const QString & theme);
	void setInitHealth(int health);
	void setTurnTime(int time);
	void setFortsMode(bool value);
	void setTeamsDivide(bool value);
	void setSolid(bool value);
	void setNetAmmo(const QString& name, const QString& ammo);

signals:
	void seedChanged(const QString & seed);
	void mapChanged(const QString & map);
	void themeChanged(const QString & theme);
	void initHealthChanged(int health);
	void turnTimeChanged(int time);
	void fortsModeChanged(bool value);
	void teamsDivideChanged(bool value);
	void solidChanged(bool value);
	void newWeaponsName(const QString& weapon);

private:
	QCheckBox * CB_mode_Forts;
	QCheckBox * CB_teamsDivide;
	QCheckBox * CB_solid;
	QGridLayout mainLayout;
	HWMapContainer* pMapContainer;
	QSpinBox * SB_TurnTime;
	QSpinBox * SB_InitHealth;
	QLabel * L_TurnTime;
	QLabel * L_InitHealth;

	QString curNetAmmoName;
	QString curNetAmmo;
};

#endif // GAMECONFIGWIDGET_H
