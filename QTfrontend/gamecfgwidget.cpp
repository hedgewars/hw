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

#include <QResizeEvent>
#include <QGroupBox>
#include <QCheckBox>
#include <QGridLayout>
#include <QSpinBox>
#include <QLabel>
#include <QMessageBox>

#include "gamecfgwidget.h"
#include "igbox.h"
#include "hwconsts.h"

GameCFGWidget::GameCFGWidget(QWidget* parent, bool externalControl) :
  QGroupBox(parent), mainLayout(this)
{
	mainLayout.setMargin(0);
//	mainLayout.setSizeConstraint(QLayout::SetMinimumSize);

	pMapContainer = new HWMapContainer(this);
	mainLayout.addWidget(pMapContainer, 0, 0);

	IconedGroupBox *GBoxOptions = new IconedGroupBox(this);
	GBoxOptions->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
	mainLayout.addWidget(GBoxOptions);

	QGridLayout *GBoxOptionsLayout = new QGridLayout(GBoxOptions);
	
	CB_mode_Forts = new QCheckBox(GBoxOptions);
	CB_mode_Forts->setText(QCheckBox::tr("Forts mode"));
	GBoxOptionsLayout->addWidget(CB_mode_Forts, 0, 0, 1, 2);

	CB_teamsDivide = new QCheckBox(GBoxOptions);
	CB_teamsDivide->setText(QCheckBox::tr("Divide teams"));
	GBoxOptionsLayout->addWidget(CB_teamsDivide, 1, 0, 1, 2);

	CB_solid = new QCheckBox(GBoxOptions);
	CB_solid->setText(QCheckBox::tr("Solid land"));
	GBoxOptionsLayout->addWidget(CB_solid, 2, 0, 1, 2);

	CB_border = new QCheckBox(GBoxOptions);
	CB_border->setText(QCheckBox::tr("Add Border"));
	GBoxOptionsLayout->addWidget(CB_border, 3, 0, 1, 2);

	L_TurnTime = new QLabel(QLabel::tr("Turn time"), GBoxOptions);
	L_InitHealth = new QLabel(QLabel::tr("Initial health"), GBoxOptions);
	L_SuddenDeath = new QLabel(QLabel::tr("Turns before SD"), GBoxOptions);
	L_CaseProb = new QLabel(QLabel::tr("Crate drops"), GBoxOptions);
	GBoxOptionsLayout->addWidget(L_TurnTime, 4, 0);
	GBoxOptionsLayout->addWidget(L_InitHealth, 5, 0);
	GBoxOptionsLayout->addWidget(L_SuddenDeath, 6, 0);
	GBoxOptionsLayout->addWidget(L_CaseProb, 7, 0);
	GBoxOptionsLayout->addWidget(new QLabel(QLabel::tr("Weapons"), GBoxOptions), 8, 0);

	SB_TurnTime = new QSpinBox(GBoxOptions);
	SB_TurnTime->setRange(1, 99);
	SB_TurnTime->setValue(45);
	SB_TurnTime->setSingleStep(15);
	
	SB_InitHealth = new QSpinBox(GBoxOptions);
	SB_InitHealth->setRange(50, 200);
	SB_InitHealth->setValue(100);
	SB_InitHealth->setSingleStep(25);
	
	SB_SuddenDeath = new QSpinBox(GBoxOptions);
	SB_SuddenDeath->setRange(0, 50);
	SB_SuddenDeath->setValue(15);
	SB_SuddenDeath->setSingleStep(3);
	
	SB_CaseProb = new FreqSpinBox(GBoxOptions);
	SB_CaseProb->setRange(0, 9);
	SB_CaseProb->setValue(5);

	GBoxOptionsLayout->addWidget(SB_TurnTime, 4, 1);
	GBoxOptionsLayout->addWidget(SB_InitHealth, 5, 1);
	GBoxOptionsLayout->addWidget(SB_SuddenDeath, 6, 1);
	GBoxOptionsLayout->addWidget(SB_CaseProb, 7, 1);
	
	WeaponsName = new QComboBox(GBoxOptions);
	GBoxOptionsLayout->addWidget(WeaponsName, 8, 1);

	connect(SB_InitHealth, SIGNAL(valueChanged(int)), this, SIGNAL(initHealthChanged(int)));
	connect(SB_TurnTime, SIGNAL(valueChanged(int)), this, SIGNAL(turnTimeChanged(int)));
	connect(SB_SuddenDeath, SIGNAL(valueChanged(int)), this, SIGNAL(suddenDeathTurnsChanged(int)));
	connect(SB_CaseProb, SIGNAL(valueChanged(int)), this, SIGNAL(caseProbabilityChanged(int)));
	connect(CB_mode_Forts, SIGNAL(toggled(bool)), this, SIGNAL(fortsModeChanged(bool)));
	connect(CB_teamsDivide, SIGNAL(toggled(bool)), this, SIGNAL(teamsDivideChanged(bool)));
	connect(CB_solid, SIGNAL(toggled(bool)), this, SIGNAL(solidChanged(bool)));
	connect(CB_border, SIGNAL(toggled(bool)), this, SIGNAL(borderChanged(bool)));
	connect(WeaponsName, SIGNAL(currentIndexChanged(int)), this, SLOT(ammoChanged(int)));

	connect(pMapContainer, SIGNAL(seedChanged(const QString &)), this, SIGNAL(seedChanged(const QString &)));
	connect(pMapContainer, SIGNAL(mapChanged(const QString &)), this, SIGNAL(mapChanged(const QString &)));
	connect(pMapContainer, SIGNAL(themeChanged(const QString &)), this, SIGNAL(themeChanged(const QString &)));
}

quint32 GameCFGWidget::getGameFlags() const
{
	quint32 result = 0;

	if (CB_mode_Forts->isChecked())
		result |= 0x01;
	if (CB_teamsDivide->isChecked())
		result |= 0x10;
	if (CB_solid->isChecked())
		result |= 0x04;
	if (CB_border->isChecked())
		result |= 0x08;

	return result;
}

QString GameCFGWidget::getCurrentSeed() const
{
  return pMapContainer->getCurrentSeed();
}

QString GameCFGWidget::getCurrentMap() const
{
  return pMapContainer->getCurrentMap();
}

QString GameCFGWidget::getCurrentTheme() const
{
  return pMapContainer->getCurrentTheme();
}

quint32 GameCFGWidget::getInitHealth() const
{
	return SB_InitHealth->value();
}

quint32 GameCFGWidget::getTurnTime() const
{
	return SB_TurnTime->value();
}

quint32 GameCFGWidget::getSuddenDeathTurns() const
{
	return SB_SuddenDeath->value();
}

quint32 GameCFGWidget::getCaseProbability() const
{
	return SB_CaseProb->value();
}

QStringList GameCFGWidget::getFullConfig() const
{
	QStringList sl;
	sl.append("eseed " + getCurrentSeed());
	sl.append(QString("e$gmflags %1").arg(getGameFlags()));
	sl.append(QString("e$turntime %1").arg(getTurnTime() * 1000));
	sl.append(QString("e$sd_turns %1").arg(getSuddenDeathTurns()));
	sl.append(QString("e$casefreq %1").arg(getCaseProbability()));
	sl.append(QString("e$template_filter %1").arg(pMapContainer->getTemplateFilter()));

	QString currentMap = getCurrentMap();
	if (currentMap.size() > 0)
		sl.append("emap " + currentMap);
	sl.append("etheme " + getCurrentTheme());
	return sl;
}

void GameCFGWidget::setNetAmmo(const QString& name, const QString& ammo)
{
	if (ammo.size() != cDefaultAmmoStore->size())
		QMessageBox::critical(this, tr("Error"), tr("Illegal ammo scheme"));

	int pos = WeaponsName->findText(name);
	if (pos == -1) {
		WeaponsName->addItem(name, ammo);
		WeaponsName->setCurrentIndex(WeaponsName->count() - 1);
	} else {
		WeaponsName->setItemData(pos, ammo);
		WeaponsName->setCurrentIndex(pos);
	}
}

void GameCFGWidget::ammoChanged(int index)
{
	if (index >= 0)
		emit newWeaponScheme(WeaponsName->itemText(index), WeaponsName->itemData(index).toString());
}

void GameCFGWidget::setParam(const QString & param, const QStringList & slValue)
{
	if (slValue.size() == 1)
	{
		QString value = slValue[0];
		if (param == "MAP") {
			pMapContainer->setMap(value);
			return;
		}
		if (param == "SEED") {
			pMapContainer->setSeed(value);
			return;
		}
		if (param == "THEME") {
			pMapContainer->setTheme(value);
			return;
		}
		if (param == "HEALTH") {
			SB_InitHealth->setValue(value.toUInt());
			return;
		}
		if (param == "TURNTIME") {
			SB_TurnTime->setValue(value.toUInt());
			return;
		}
		if (param == "SD_TURNS") {
			SB_SuddenDeath->setValue(value.toUInt());
			return;
		}
		if (param == "CASEFACTOR") {
			SB_CaseProb->setValue(value.toUInt());
			return;
		}
		if (param == "FORTSMODE") {
			CB_mode_Forts->setChecked(value.toUInt() != 0);
			return;
		}
		if (param == "DIVIDETEAMS") {
			CB_teamsDivide->setChecked(value.toUInt() != 0);
			return;
		}
		if (param == "SOLIDLAND") {
			CB_solid->setChecked(value.toUInt() != 0);
			return;
		}
		if (param == "BORDER") {
			CB_border->setChecked(value.toUInt() != 0);
			return;
		}
/*		if (param == "TEMPLATE_FILTER") {
			emit templateFilterChanged(lst[2].toUInt());
			return;
		}
*/	}

	if (slValue.size() == 2)
	{
		if (param == "AMMO") {
			setNetAmmo(slValue[0], slValue[1]);
			return;
		}
	}
}

