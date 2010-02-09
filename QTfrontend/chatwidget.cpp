/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2009 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QTextBrowser>
#include <QLineEdit>
#include <QAction>
#include <QApplication>
#include <QTextDocument>
#include <QDir>
#include <QSettings>

#include "hwconsts.h"
#include "SDLs.h"
#include "gameuiconfig.h"
#include "chatwidget.h"

HWChatWidget::HWChatWidget(QWidget* parent, QSettings * gameSettings, SDLInteraction * sdli) :
  QWidget(parent),
  mainLayout(this)
{
    this->gameSettings = gameSettings;
    this->sdli = sdli;

	mainLayout.setSpacing(1);
	mainLayout.setMargin(1);
	mainLayout.setSizeConstraint(QLayout::SetMinimumSize);
	mainLayout.setColumnStretch(0, 75);
	mainLayout.setColumnStretch(1, 25);

	chatEditLine = new QLineEdit(this);
	chatEditLine->setMaxLength(300);
	connect(chatEditLine, SIGNAL(returnPressed()), this, SLOT(returnPressed()));

	mainLayout.addWidget(chatEditLine, 1, 0, 1, 2);

	chatText = new QTextBrowser(this);
	chatText->setMinimumHeight(20);
	chatText->setMinimumWidth(10);
	chatText->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	chatText->setOpenExternalLinks(true);
	mainLayout.addWidget(chatText, 0, 0);

	chatNicks = new QListWidget(this);
	chatNicks->setMinimumHeight(10);
	chatNicks->setMinimumWidth(10);
	chatNicks->setSortingEnabled(true);
	chatNicks->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
	chatNicks->setContextMenuPolicy(Qt::ActionsContextMenu);
	connect(chatNicks, SIGNAL(itemDoubleClicked(QListWidgetItem *)),
		this, SLOT(chatNickDoubleClicked(QListWidgetItem *)));

	mainLayout.addWidget(chatNicks, 0, 1);

	acInfo = new QAction(QAction::tr("Info"), chatNicks);
	connect(acInfo, SIGNAL(triggered(bool)), this, SLOT(onInfo()));
	acKick = new QAction(QAction::tr("Kick"), chatNicks);
	connect(acKick, SIGNAL(triggered(bool)), this, SLOT(onKick()));
	acBan = new QAction(QAction::tr("Ban"), chatNicks);
	connect(acBan, SIGNAL(triggered(bool)), this, SLOT(onBan()));
	acFollow = new QAction(QAction::tr("Follow"), chatNicks);
	connect(acFollow, SIGNAL(triggered(bool)), this, SLOT(onFollow()));

	chatNicks->insertAction(0, acInfo);
	chatNicks->insertAction(0, acFollow);
}

void HWChatWidget::returnPressed()
{
	emit chatLine(chatEditLine->text());
	chatEditLine->clear();
}

void HWChatWidget::onChatString(const QString& str)
{
	if (chatStrings.size() > 250)
		chatStrings.removeFirst();

	QString formattedStr = Qt::escape(str.mid(1));
	if (str.startsWith("\x03"))
		formattedStr = QString("<font color=grey>%1</font>").arg(formattedStr);
	else if (str.startsWith("\x02"))
		formattedStr = QString("<font color=magenta>%1</font>").arg(formattedStr);


	chatStrings.append(formattedStr);

	chatText->setHtml(chatStrings.join("<br>"));

	chatText->moveCursor(QTextCursor::End);
}

void HWChatWidget::onServerMessage(const QString& str)
{
	if (chatStrings.size() > 250)
		chatStrings.removeFirst();

	chatStrings.append("<hr>" + str + "<hr>");

	chatText->setHtml(chatStrings.join("<br>"));

	chatText->moveCursor(QTextCursor::End);
}

void HWChatWidget::nickAdded(const QString& nick)
{
    Mix_Chunk *sound;
    QDir tmpdir;

	QListWidgetItem * item = new QListWidgetItem(nick);
	item->setIcon(QIcon(":/res/hh_small.png"));
	chatNicks->addItem(item);

    if(gameSettings->value("audio/sound", true).toBool()) {
       sdli->SDLMusicInit();
       tmpdir.cd(datadir->absolutePath());
       tmpdir.cd("Sounds/");
       sound = Mix_LoadWAV(QString(tmpdir.absolutePath() + "/switchhog.ogg").toLocal8Bit().constData());
       Mix_PlayChannel(-1, sound, 0);
    }
}

void HWChatWidget::nickRemoved(const QString& nick)
{
	QList<QListWidgetItem *> items = chatNicks->findItems(nick, Qt::MatchExactly);
	for(QList<QListWidgetItem *>::iterator it=items.begin(); it!=items.end();) {
		chatNicks->takeItem(chatNicks->row(*it));
		++it;
	}
}

void HWChatWidget::clear()
{
	chatText->clear();
	chatStrings.clear();
	chatNicks->clear();
}

void HWChatWidget::onKick()
{
	QListWidgetItem * curritem = chatNicks->currentItem();
	if (curritem)
		emit kick(curritem->text());
}

void HWChatWidget::onBan()
{
	QListWidgetItem * curritem = chatNicks->currentItem();
	if (curritem)
		emit ban(curritem->text());
}

void HWChatWidget::onInfo()
{
	QListWidgetItem * curritem = chatNicks->currentItem();
	if (curritem)
		emit info(curritem->text());
}

void HWChatWidget::onFollow()
{
	QListWidgetItem * curritem = chatNicks->currentItem();
	if (curritem)
		emit follow(curritem->text());
}

void HWChatWidget::chatNickDoubleClicked(QListWidgetItem * item)
{
	if (item) onFollow();
}

void HWChatWidget::setReadyStatus(const QString & nick, bool isReady)
{
	QList<QListWidgetItem *> items = chatNicks->findItems(nick, Qt::MatchExactly);
	if (items.size() != 1)
	{
		qWarning("Bug: cannot find user in chat");
		return;
	}

	if(isReady)
		items[0]->setIcon(QIcon(":/res/lightbulb_on.png"));
	else
		items[0]->setIcon(QIcon(":/res/lightbulb_off.png"));
}

void HWChatWidget::adminAccess(bool b)
{
	chatNicks->removeAction(acKick);
	chatNicks->removeAction(acBan);

	if(b)
	{
		chatNicks->insertAction(0, acKick);
//		chatNicks->insertAction(0, acBan);
	}
}
