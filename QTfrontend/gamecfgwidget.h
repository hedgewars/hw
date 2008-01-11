/*
 * Hedgewars, a worms-like game
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

#include "mapContainer.h"

class QCheckBox;
class QVBoxLayout;
class QSpinBox;
class QLabel;

class GameCFGWidget : public QWidget
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

	QString getNetAmmo() const; // FIXME: hack - this class should contain all ammo states itself

	QComboBox* WeaponsName;

public slots:
	void setSeed(const QString & seed);
	void setMap(const QString & map);
	void setTheme(const QString & theme);
	void setInitHealth(quint32 health);
	void setTurnTime(quint32 time);
	void setFortsMode(bool value);
	void setNetAmmo(const QString&);

signals:
	void seedChanged(const QString & seed);
	void mapChanged(const QString & map);
	void themeChanged(const QString & theme);
	void initHealthChanged(quint32 health);
	void turnTimeChanged(quint32 time);
	void fortsModeChanged(bool value);
	void newWeaponsName(const QString& weapon);

private:
	QCheckBox * CB_mode_Forts;
	QVBoxLayout mainLayout;
	HWMapContainer* pMapContainer;
	QSpinBox * SB_TurnTime;
	QSpinBox * SB_InitHealth;
	QLabel * L_TurnTime;
	QLabel * L_InitHealth;

	QString curNetAmmo;

private slots:
	void onSeedChanged(const QString & seed);
	void onMapChanged(const QString & map);
	void onThemeChanged(const QString & theme);
	void onInitHealthChanged(int health);
	void onTurnTimeChanged(int time);
	void onFortsModeChanged(bool value);

};

#endif // GAMECONFIGWIDGET_H
