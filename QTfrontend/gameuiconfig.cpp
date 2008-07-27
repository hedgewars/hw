/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QCheckBox>
#include <QLineEdit>
#include <QDesktopWidget>
#include <QApplication>

#include "gameuiconfig.h"
#include "hwform.h"
#include "pages.h"
#include "hwconsts.h"
#include "fpsedit.h"

GameUIConfig::GameUIConfig(HWForm * FormWidgets, const QString & fileName)
	: QSettings(fileName, QSettings::IniFormat)
{
	Form = FormWidgets;

	Form->resize(value("window/width", 640).toUInt(), value("window/height", 450).toUInt());

	int t = Form->ui.pageOptions->CBResolution->findText(value("video/resolution").toString());
	Form->ui.pageOptions->CBResolution->setCurrentIndex((t < 0) ? 0 : t);
	Form->ui.pageOptions->CBFullscreen->setChecked(value("video/fullscreen", false).toBool());

	Form->ui.pageOptions->CBEnableSound->setChecked(value("audio/sound", true).toBool());
	Form->ui.pageOptions->CBEnableMusic->setChecked(value("audio/music", true).toBool());

	Form->ui.pageOptions->editNetNick->setText(value("net/nick", QLineEdit::tr("unnamed")).toString());

	delete netHost;
	netHost = new QString(value("net/ip", "").toString());
	netPort = value("net/port", 46631).toUInt();

	Form->ui.pageNetServer->leServerDescr->setText(value("net/servername", "hedgewars server").toString());
	Form->ui.pageNetServer->sbPort->setValue(value("net/serverport", 46631).toUInt());

	Form->ui.pageOptions->CBShowFPS->setChecked(value("fps/show", false).toBool());
	Form->ui.pageOptions->fpsedit->setValue(value("fps/interval", 27).toUInt());

	Form->ui.pageOptions->CBAltDamage->setChecked(value("misc/altdamage", false).toBool());

	depth = QApplication::desktop()->depth();
	if (depth < 16) depth = 16;
	else if (depth > 16) depth = 32;
}

QStringList GameUIConfig::GetTeamsList()
{
	QStringList teamslist = cfgdir->entryList(QStringList("*.cfg"));
	QStringList cleanedList;
	for (QStringList::Iterator it = teamslist.begin(); it != teamslist.end(); ++it ) {
	  QString tmpTeamStr=(*it).replace(QRegExp("^(.*)\\.cfg$"), "\\1");
	  cleanedList.push_back(tmpTeamStr);
	}
	return cleanedList;
}

void GameUIConfig::SaveOptions()
{
	setValue("video/resolution", Form->ui.pageOptions->CBResolution->currentText());
	setValue("video/fullscreen", vid_Fullscreen());

	setValue("audio/sound", isSoundEnabled());
	setValue("audio/music", isMusicEnabled());

	setValue("net/nick", netNick());
	setValue("net/ip", *netHost);
	setValue("net/port", netPort);
	setValue("net/servername", Form->ui.pageNetServer->leServerDescr->text());
	setValue("net/serverport", Form->ui.pageNetServer->sbPort->value());

	setValue("fps/show", isShowFPSEnabled());
	setValue("fps/interval", Form->ui.pageOptions->fpsedit->value());

	setValue("misc/altdamage", isAltDamageEnabled());

	setValue("window/width", Form->width());
	setValue("window/height", Form->height());
}

QRect GameUIConfig::vid_Resolution()
{
	QRect result(0, 0, 640, 480);
	QStringList wh = Form->ui.pageOptions->CBResolution->currentText().split('x');
	if (wh.size() == 2)
	{
		result.setWidth(wh[0].toInt());
		result.setHeight(wh[1].toInt());
	}
	return result;
}

bool GameUIConfig::vid_Fullscreen()
{
	return Form->ui.pageOptions->CBFullscreen->isChecked();
}

bool GameUIConfig::isSoundEnabled()
{
	return Form->ui.pageOptions->CBEnableSound->isChecked();
}

bool GameUIConfig::isMusicEnabled()
{
	return Form->ui.pageOptions->CBEnableMusic->isChecked();
}

bool GameUIConfig::isShowFPSEnabled()
{
	return Form->ui.pageOptions->CBShowFPS->isChecked();
}

bool GameUIConfig::isAltDamageEnabled()
{
	return Form->ui.pageOptions->CBAltDamage->isChecked();;
}

quint8 GameUIConfig::timerInterval()
{
	return 35 - Form->ui.pageOptions->fpsedit->value();
}

quint8 GameUIConfig::bitDepth()
{
	return depth;
}

QString GameUIConfig::netNick()
{
	return Form->ui.pageOptions->editNetNick->text();
}
