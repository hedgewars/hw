/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QMessageBox>
#include "gameuiconfig.h"
#include "hwform.h"
#include "pages.h"
#include "hwconsts.h"
#include "fpsedit.h"

GameUIConfig::GameUIConfig(HWForm * FormWidgets, const QString & fileName)
	: QSettings(fileName, QSettings::IniFormat)
{
	Form = FormWidgets;

	Form->ui.pageOptions->CBResolution->setCurrentIndex(value("video/resolution").toUInt());
	Form->ui.pageOptions->CBFullscreen->setChecked(value("video/fullscreen", false).toBool());

	Form->ui.pageOptions->CBEnableSound->setChecked(value("audio/sound", true).toBool());

	Form->ui.pageNet->editNetNick->setText(value("net/nick", QLineEdit::tr("unnamed")).toString());
	Form->ui.pageNet->editIP->setText(value("net/ip", "").toString());
	Form->ui.pageOptions->CBShowFPS->setChecked(value("fps/show", false).toBool());
	Form->ui.pageOptions->fpsedit->setValue(value("fps/interval", 27).toUInt());
}

QStringList GameUIConfig::GetTeamsList()
{
	QStringList teamslist = cfgdir->entryList(QStringList("*.cfg"));
	QStringList cleanedList;
	for (QStringList::Iterator it = teamslist.begin(); it != teamslist.end(); ++it ) {
	  QString tmpTeamStr=(*it).replace(QRegExp("^(.*).cfg$"), "\\1");
	  cleanedList.push_back(tmpTeamStr);
	}
	return cleanedList;
}

void GameUIConfig::SaveOptions()
{
	setValue("video/resolution", vid_Resolution());
	setValue("video/fullscreen", vid_Fullscreen());

	setValue("audio/sound", isSoundEnabled());

	setValue("net/nick", Form->ui.pageNet->editNetNick->text());
	setValue("net/ip", Form->ui.pageNet->editIP->text());

	setValue("fps/show", isShowFPSEnabled());
	setValue("fps/interval", Form->ui.pageOptions->fpsedit->value());
}

int GameUIConfig::vid_Resolution()
{
	return Form->ui.pageOptions->CBResolution->currentIndex();
}

bool GameUIConfig::vid_Fullscreen()
{
	return Form->ui.pageOptions->CBFullscreen->isChecked();
}

bool GameUIConfig::isSoundEnabled()
{
	return Form->ui.pageOptions->CBEnableSound->isChecked();
}

bool GameUIConfig::isShowFPSEnabled()
{
	return Form->ui.pageOptions->CBShowFPS->isChecked();
}

quint8 GameUIConfig::timerInterval()
{
	return 35 - Form->ui.pageOptions->fpsedit->value();
}
