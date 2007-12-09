/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2007 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QHttp>
#include <QListWidget>
#include <QMessageBox>

#include "netwwwwidget.h"
#include "hwconsts.h"

HWNetWwwWidget::HWNetWwwWidget(QWidget* parent) :
  HWNetServersWidget(parent)
{
	http = new QHttp(this);
	http->setHost("www.hedgewars.org", 80);
	connect(http, SIGNAL(requestFinished(int, bool)), this, SLOT(onClientRead(int, bool)));
}
// http://hedgewars.org/games/create
// http://www.hedgewars.org/games/update_game?id=1&key=pufidzuk
// http://www.hedgewars.org/games/destroy_game?id=5&key=wrdeough
void HWNetWwwWidget::updateList()
{
	http->abort();
// example for adding game to server list
/*	QString request = QString("game[title]=%1&game[port]=%2&game[password]=%3&game[protocol_version]=%4")
			.arg("hedgewarsserver")
			.arg(46631)
			.arg(false ? "true" : "false")
			.arg(*cProtoVer);
	http->post("/games/create", request.toUtf8());
*/
// query game list
	QString request = QString("protocol_version=%1")
			.arg(*cProtoVer);
	http->post("/games/list_games", request.toUtf8());

	serversList->clear();
}

void HWNetWwwWidget::onClientRead(int id, bool error)
{
	if (error)
	{
		QMessageBox::critical(this, tr("Error"), http->errorString());
		return;
	}
	serversList->addItem(http->readAll());
}
