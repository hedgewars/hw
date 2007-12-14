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
#include <QMessageBox>
#include <QTimer>
#include <QStringList>
#include "netwwwserver.h"
#include "hwconsts.h"

HWNetWwwServer::HWNetWwwServer(QObject *parent, const QString & descr, quint16 port) :
  HWNetRegisterServer(parent, descr, port), timer(0)
{
	destroyPosted = false;
	destroyPostId = 0;

	http = new QHttp(this);
	http->setHost("www.hedgewars.org", 80);
	connect(http, SIGNAL(requestFinished(int, bool)), this, SLOT(onClientRead(int, bool)));

	QString request = QString("game[title]=%1&game[port]=%2&game[password]=%3&game[protocol_version]=%4")
			.arg(descr)
			.arg(port)
			.arg(false ? "true" : "false")
			.arg(*cProtoVer);
	http->post("/games/create", request.toUtf8());
}

void HWNetWwwServer::onClientRead(int id, bool error)
{
	if (destroyPosted && (id == destroyPostId))
	{
		deleteLater();
		return;
	}

	if (error)
	{
		QMessageBox::critical(0,
				tr("Error"),
				tr("Server registration error") + "\n" +
				http->errorString());
		return;
	}

	QString str = http->readAll();

	if (!str.size()) return; // ??

	if (str[1] == QChar('0')) return; // error on server
	if (!timer)
	{
		QStringList sl = str.split(',');
		if (sl.size() != 2) return;
		servid = sl[0];
		servkey = sl[1];

		timer = new QTimer(this);
		connect(timer, SIGNAL(timeout()), this, SLOT(updateInList()));
		timer->start(60000);
	}
}

void HWNetWwwServer::updateInList()
{
	QString request = QString("id=%1&key=%2")
			.arg(servid)
			.arg(servkey);
	http->post("/games/update_game", request.toUtf8());
}

void HWNetWwwServer::unregister()
{
	qDebug("delete server");
	QString request = QString("id=%1&key=%2")
			.arg(servid)
			.arg(servkey);
	destroyPostId = http->post("/games/destroy_game", request.toUtf8());
	destroyPosted = true;
}
