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
#include <QDebug>
#include <QDomDocument>
#include <QDomElement>
#include <QDomNode>
#include <QDomText>

#include "netwwwwidget.h"
#include "hwconsts.h"

HWNetWwwWidget::HWNetWwwWidget(QWidget* parent) :
  HWNetServersWidget(parent)
{
	serversList->setModel(new HWNetWwwModel);
}

void HWNetWwwWidget::updateList()
{
	static_cast<HWNetWwwModel *>(serversList->model())->updateList();
}


HWNetWwwModel::HWNetWwwModel(QObject *parent) : QAbstractTableModel(parent)
{
	http = new QHttp(this);
	http->setHost("www.hedgewars.org", 80);
	connect(http, SIGNAL(requestFinished(int, bool)), this, SLOT(onClientRead(int, bool)));
}

QVariant HWNetWwwModel::data(const QModelIndex &index,
                             int role) const
{
	if (!index.isValid() || index.row() < 0
		|| index.row() >= games.size()
		|| role != Qt::DisplayRole)
	return QVariant();

	return games[index.row()][index.column()];
}

QVariant HWNetWwwModel::headerData(int section,
            Qt::Orientation orientation, int role) const
{
	if (role != Qt::DisplayRole)
		return QVariant();

	if (orientation == Qt::Horizontal)
	{
		switch (section)
		{
			case 0: return tr("Title");
			case 1: return tr("IP");
			case 2: return tr("Port");
			default: return QVariant();
		}
	} else
		return QString("%1").arg(section + 1);
}

int HWNetWwwModel::rowCount(const QModelIndex &parent) const
{
	if (parent.isValid())
		return 0;
	else
		return games.size();
}

int HWNetWwwModel::columnCount(const QModelIndex & parent) const
{
	if (parent.isValid())
		return 0;
	else
		return 3;
}

void HWNetWwwModel::updateList()
{
	QString request = QString("protocol_version=%1")
			.arg(*cProtoVer);
	http->post("/games/list_games", request.toUtf8());

	games.clear();

	reset();
}

void HWNetWwwModel::onClientRead(int id, bool error)
{
	if (error)
	{
		qWarning() << "Error" << http->errorString();
		return;
	}
	games.clear();

	QDomDocument doc;
	if (!doc.setContent(http->readAll())) return;

	QDomElement docElem = doc.documentElement();

	QDomNode n = docElem.firstChild();
	while (!n.isNull())
	{
		QDomElement game = n.toElement(); // try to convert the node to an element.

		if(!game.isNull())
		{
			QDomNode p = game.firstChild();
			QStringList sl;
			sl << "-" << "-" << "-";
			while (!p.isNull())
			{
				QDomElement e = p.toElement();

				if(!p.isNull())
				{
					int i = -1;
					if (e.tagName() == "title") i = 0;
					else if (e.tagName() == "ip") i = 1;
					else if (e.tagName() == "port") i = 2;

					QDomText t = e.firstChild().toText();
					if(!t.isNull() && (i >= 0))
						sl[i] = t.data();
				}
				p = p.nextSibling();
			}
			games.append(sl);
		}
		n = n.nextSibling();
	}

	reset();
}
