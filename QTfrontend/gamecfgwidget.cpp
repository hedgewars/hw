/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006, 2007, 2009 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QTableView>
#include <QPushButton>

#include "gamecfgwidget.h"
#include "igbox.h"
#include "hwconsts.h"
#include "ammoSchemeModel.h"

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

	QTableView * tv = new QTableView(this);
	tv->setModel(new AmmoSchemeModel);
	GBoxOptionsLayout->addWidget(tv, 0, 0, 1, 2);

	QPushButton * goToSchemePage = new QPushButton(GBoxOptions);
	goToSchemePage->setText(tr("Edit schemes"));
	GBoxOptionsLayout->addWidget(goToSchemePage, 1, 0, 1, 2);
	connect(goToSchemePage, SIGNAL(clicked()), this, SIGNAL(goToSchemes()));
	
	GBoxOptionsLayout->addWidget(new QLabel(QLabel::tr("Weapons"), GBoxOptions), 8, 0);

	WeaponsName = new QComboBox(GBoxOptions);
	GBoxOptionsLayout->addWidget(WeaponsName, 8, 1);
	
	connect(WeaponsName, SIGNAL(currentIndexChanged(int)), this, SLOT(ammoChanged(int)));

	connect(pMapContainer, SIGNAL(seedChanged(const QString &)), this, SLOT(seedChanged(const QString &)));
	connect(pMapContainer, SIGNAL(mapChanged(const QString &)), this, SLOT(mapChanged(const QString &)));
	connect(pMapContainer, SIGNAL(themeChanged(const QString &)), this, SLOT(themeChanged(const QString &)));
	connect(pMapContainer, SIGNAL(newTemplateFilter(int)), this, SLOT(templateFilterChanged(int)));
}

quint32 GameCFGWidget::getGameFlags() const
{
	quint32 result = 0;

/*	if (CB_mode_Forts->isChecked())
		result |= 0x01;
	if (CB_teamsDivide->isChecked())
		result |= 0x10;
	if (CB_solid->isChecked())
		result |= 0x04;
	if (CB_border->isChecked())
		result |= 0x08;*/

	return result;
}

quint32 GameCFGWidget::getInitHealth() const
{
//	return SB_InitHealth->value();
}

QStringList GameCFGWidget::getFullConfig() const
{
	QStringList sl;
	sl.append("eseed " + pMapContainer->getCurrentSeed());
	sl.append(QString("e$gmflags %1").arg(getGameFlags()));
//	sl.append(QString("e$turntime %1").arg(SB_TurnTime->value() * 1000));
//	sl.append(QString("e$sd_turns %1").arg(SB_SuddenDeath->value()));
//	sl.append(QString("e$casefreq %1").arg(SB_CaseProb->value()));
	sl.append(QString("e$template_filter %1").arg(pMapContainer->getTemplateFilter()));

	QString currentMap = pMapContainer->getCurrentMap();
	if (currentMap.size() > 0)
		sl.append("emap " + currentMap);
	sl.append("etheme " + pMapContainer->getCurrentTheme());
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

void GameCFGWidget::fullNetConfig()
{
	ammoChanged(WeaponsName->currentIndex());
	
	seedChanged(pMapContainer->getCurrentSeed());
	templateFilterChanged(pMapContainer->getTemplateFilter());
	themeChanged(pMapContainer->getCurrentTheme());

	// map must be the last
	QString map = pMapContainer->getCurrentMap();
	if (map.size())
		mapChanged(map);
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
//			SB_InitHealth->setValue(value.toUInt());
			return;
		}
		if (param == "TURNTIME") {
//			SB_TurnTime->setValue(value.toUInt());
			return;
		}
		if (param == "SD_TURNS") {
//			SB_SuddenDeath->setValue(value.toUInt());
			return;
		}
		if (param == "CASEFACTOR") {
//			SB_CaseProb->setValue(value.toUInt());
			return;
		}
		if (param == "FORTSMODE") {
//			CB_mode_Forts->setChecked(value.toUInt() != 0);
			return;
		}
		if (param == "DIVIDETEAMS") {
//			CB_teamsDivide->setChecked(value.toUInt() != 0);
			return;
		}
		if (param == "SOLIDLAND") {
//			CB_solid->setChecked(value.toUInt() != 0);
			return;
		}
		if (param == "BORDER") {
//			CB_border->setChecked(value.toUInt() != 0);
			return;
		}
		if (param == "TEMPLATE") {
			pMapContainer->setTemplateFilter(value.toUInt());
			return;
		}
	}

	if (slValue.size() == 2)
	{
		if (param == "AMMO") {
			setNetAmmo(slValue[0], slValue[1]);
			return;
		}
	}
}

void GameCFGWidget::ammoChanged(int index)
{
	if (index >= 0)
		emit paramChanged(
			"AMMO",
			QStringList() << WeaponsName->itemText(index) << WeaponsName->itemData(index).toString()
		);
}

void GameCFGWidget::mapChanged(const QString & value)
{
	emit paramChanged("MAP", QStringList(value));
}

void GameCFGWidget::templateFilterChanged(int value)
{
	emit paramChanged("TEMPLATE", QStringList(QString::number(value)));
}

void GameCFGWidget::seedChanged(const QString & value)
{
	emit paramChanged("SEED", QStringList(value));
}

void GameCFGWidget::themeChanged(const QString & value)
{
	emit paramChanged("THEME", QStringList(value));
}
