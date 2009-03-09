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
#include <QSpinBox>

#include "mapContainer.h"

class QCheckBox;
class QVBoxLayout;
class QLabel;
class FreqSpinBox;

class FreqSpinBox : public QSpinBox
{
	Q_OBJECT

public:
	FreqSpinBox(QWidget* parent) : QSpinBox(parent)
	{

	}

	QString textFromValue ( int value ) const
	{
		switch (value)
		{
			case 0 : return tr("Never");
			case 1 : return tr("Every turn");
			default : return tr("Each %1 turn").arg(value);
		}
	}
};

class GameCFGWidget : public QGroupBox
{
	Q_OBJECT

public:
	GameCFGWidget(QWidget* parent, bool externalControl=false);
	quint32 getGameFlags() const;
	quint32 getInitHealth() const;
	QStringList getFullConfig() const;
	QComboBox * WeaponsName;
	HWMapContainer* pMapContainer;

public slots:
	void setParam(const QString & param, const QStringList & value);
	void fullNetConfig();

signals:
	void paramChanged(const QString & param, const QStringList & value);

private slots:
	void ammoChanged(int index);
	void borderChanged(bool);
	void caseProbabilityChanged(int);
	void fortsModeChanged(bool);
	void initHealthChanged(int);
	void mapChanged(const QString &);
	void seedChanged(const QString &);
	void solidChanged(bool);
	void suddenDeathTurnsChanged(int);
	void teamsDivideChanged(bool);
	void themeChanged(const QString &);
	void turnTimeChanged(int);

private:
	QCheckBox * CB_mode_Forts;
	QCheckBox * CB_teamsDivide;
	QCheckBox * CB_solid;
	QCheckBox * CB_border;
	QGridLayout mainLayout;
	QSpinBox * SB_TurnTime;
	QSpinBox * SB_InitHealth;
	QSpinBox * SB_SuddenDeath;
	FreqSpinBox * SB_CaseProb;
	QLabel * L_TurnTime;
	QLabel * L_InitHealth;
	QLabel * L_SuddenDeath;
	QLabel * L_CaseProb;

	QString curNetAmmoName;
	QString curNetAmmo;

	void setNetAmmo(const QString& name, const QString& ammo);
};

#endif // GAMECONFIGWIDGET_H
