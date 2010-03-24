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
#include <QFile>
#include <QTextStream>

#include "hwconsts.h"
#include "SDLs.h"
#include "gameuiconfig.h"
#include "chatwidget.h"

HWChatWidget::HWChatWidget(QWidget* parent, QSettings * gameSettings, SDLInteraction * sdli, bool notify) :
  QWidget(parent),
  mainLayout(this)
{
    this->gameSettings = gameSettings;
    this->sdli = sdli;
    this->notify = notify;
    if(notify && gameSettings->value("frontend/sound", true).toBool()) {
       QDir tmpdir;

       tmpdir.cd(datadir->absolutePath());
       tmpdir.cd("Sounds/voices");
       sdli->SDLMusicInit();
       sound[0] = Mix_LoadWAV(QString(tmpdir.absolutePath() + "/Classic/Hello.ogg").toLocal8Bit().constData());
       sound[1] = Mix_LoadWAV(QString(tmpdir.absolutePath() + "/Default/Hello.ogg").toLocal8Bit().constData());
       sound[2] = Mix_LoadWAV(QString(tmpdir.absolutePath() + "/Mobster/Hello.ogg").toLocal8Bit().constData());
       sound[3] = Mix_LoadWAV(QString(tmpdir.absolutePath() + "/Russian/Hello.ogg").toLocal8Bit().constData());
    }

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
    connect(chatNicks, SIGNAL(currentRowChanged(int)),
        this, SLOT(chatNickSelected(int)));

    mainLayout.addWidget(chatNicks, 0, 1);

    acInfo = new QAction(QAction::tr("Info"), chatNicks);
    connect(acInfo, SIGNAL(triggered(bool)), this, SLOT(onInfo()));
    acKick = new QAction(QAction::tr("Kick"), chatNicks);
    connect(acKick, SIGNAL(triggered(bool)), this, SLOT(onKick()));
    acBan = new QAction(QAction::tr("Ban"), chatNicks);
    connect(acBan, SIGNAL(triggered(bool)), this, SLOT(onBan()));
    acFollow = new QAction(QAction::tr("Follow"), chatNicks);
    connect(acFollow, SIGNAL(triggered(bool)), this, SLOT(onFollow()));
    acIgnore = new QAction(QAction::tr("Ignore"), chatNicks);
    connect(acIgnore, SIGNAL(triggered(bool)), this, SLOT(onIgnore()));
    acFriend = new QAction(QAction::tr("Add friend"), chatNicks);
    connect(acFriend, SIGNAL(triggered(bool)), this, SLOT(onFriend()));

    chatNicks->insertAction(0, acInfo);
    chatNicks->insertAction(0, acFollow);
    chatNicks->insertAction(0, acIgnore);
    chatNicks->insertAction(0, acFriend);
    
    showReady = false;
}

void HWChatWidget::loadList(QStringList & list, const QString & file)
{
    list.clear();
    QFile txt((cfgdir->absolutePath() + "/" + file).toLocal8Bit().constData());
    if(!txt.open(QIODevice::ReadOnly))
        return;
    QTextStream stream(&txt);
    stream.setCodec("UTF-8");

    while(!stream.atEnd())
    {
        QString str = stream.readLine();
        if(str.startsWith(";") || str.length() == 0)
            continue;
        list << str.trimmed();
    }
    //readd once we require newer Qt than 4.4
    //list.removeDuplicates();
    txt.close();
}

void HWChatWidget::saveList(QStringList & list, const QString & file)
{
    QFile txt((cfgdir->absolutePath() + "/" + file).toLocal8Bit().constData());
    if(!txt.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    QTextStream stream(&txt);
    stream.setCodec("UTF-8");

    stream << "; this list is used by Hedgewars - do not edit it unless you know what you're doing!" << endl;
    for(int i = 0; i < list.size(); i++)
        stream << list[i] << endl;
    txt.close();
}

void HWChatWidget::updateIcon(QListWidgetItem *item)
{
    QString nick = item->text();

    if(ignoreList.contains(nick, Qt::CaseInsensitive))
    {
        item->setIcon(QIcon(showReady ? (item->data(Qt::UserRole).toBool() ? ":/res/chat_ignore_on" : ":/res/chat_ignore_off") : ":/res/chat_ignore.png"));
        item->setForeground(Qt::gray);
    }
    else if(friendsList.contains(nick, Qt::CaseInsensitive))
    {
        item->setIcon(QIcon(showReady ? (item->data(Qt::UserRole).toBool() ? ":/res/chat_friend_on" : ":/res/chat_friend_off") : ":/res/chat_friend.png"));
        item->setForeground(Qt::green);
    }
    else
    {
        item->setIcon(QIcon(showReady ? (item->data(Qt::UserRole).toBool() ? ":/res/chat_default_on" : ":/res/chat_default_off") : ":/res/chat_default.png"));
        item->setForeground(QBrush(QColor(0xff, 0xcc, 0x00)));
    }
}

void HWChatWidget::updateIcons()
{
    for(int i = 0; i < chatNicks->count(); i++)
        updateIcon(chatNicks->item(i));
}

void HWChatWidget::loadLists(const QString & nick)
{
    loadList(ignoreList, nick.toLower() + "_ignore.txt");
    loadList(friendsList, nick.toLower() + "_friends.txt");
    updateIcons();
}

void HWChatWidget::saveLists(const QString & nick)
{
    saveList(ignoreList, nick.toLower() + "_ignore.txt");
    saveList(friendsList, nick.toLower() + "_friends.txt");
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
    QStringList parts = formattedStr.split(QRegExp("\\W+"), QString::SkipEmptyParts);

    if (!formattedStr.startsWith(" ***")) // don't ignore status messages
    {
        if (formattedStr.startsWith(" *")) // emote
            parts[0] = parts[1];
        if(parts.size() > 0 && ignoreList.contains(parts[0], Qt::CaseInsensitive))
            return;
    }

    QString color("");
    bool isFriend = friendsList.contains(parts[0], Qt::CaseInsensitive);
    
    if (str.startsWith("\x03"))
        color = QString("#c0c0c0");
    else if (str.startsWith("\x02"))
        color = QString(isFriend ? "#00ff00" : "#ff00ff");
    else if (isFriend)
        color = QString("#00c000");

    if(color.compare("") != 0)
        formattedStr = QString("<font color=\"%2\">%1</font>").arg(formattedStr).arg(color);

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

void HWChatWidget::nickAdded(const QString& nick, bool notifyNick)
{
    QListWidgetItem * item = new QListWidgetItem(nick);
    updateIcon(item);
    chatNicks->addItem(item);

    if(notifyNick && notify && gameSettings->value("frontend/sound", true).toBool()) {
       Mix_PlayChannel(-1, sound[rand()%4], 0);
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

void HWChatWidget::onIgnore()
{
    QListWidgetItem * curritem = chatNicks->currentItem();
    if(!curritem)
        return;

    if(ignoreList.contains(curritem->text(), Qt::CaseInsensitive)) // already on list - remove him
    {
        ignoreList.removeAll(curritem->text().toLower());
        onChatString(HWChatWidget::tr("%1 *** %2 has been removed from your ignore list").arg('\x03').arg(curritem->text()));
    }
    else // not on list - add
    {
        ignoreList << curritem->text().toLower();
        onChatString(HWChatWidget::tr("%1 *** %2 has been added to your ignore list").arg('\x03').arg(curritem->text()));
    }
    updateIcon(curritem); // update icon
    chatNickSelected(0); // update context menu
}

void HWChatWidget::onFriend()
{
    QListWidgetItem * curritem = chatNicks->currentItem();
    if(!curritem)
        return;

    if(friendsList.contains(curritem->text(), Qt::CaseInsensitive)) // already on list - remove him
    {
        friendsList.removeAll(curritem->text().toLower());
        onChatString(HWChatWidget::tr("%1 *** %2 has been removed from your friends list").arg('\x03').arg(curritem->text()));
    }
    else // not on list - add
    {
        friendsList << curritem->text().toLower();
        onChatString(HWChatWidget::tr("%1 *** %2 has been added to your friends list").arg('\x03').arg(curritem->text()));
    }
    updateIcon(curritem); // update icon
    chatNickSelected(0); // update context menu
}

void HWChatWidget::chatNickDoubleClicked(QListWidgetItem * item)
{
    if (item) onFollow();
}

void HWChatWidget::chatNickSelected(int index)
{
    QListWidgetItem* item = chatNicks->currentItem();
    if (!item)
        return;

    // update context menu labels according to possible action
    if(ignoreList.contains(item->text(), Qt::CaseInsensitive))
        acIgnore->setText(QAction::tr("Unignore"));
    else
        acIgnore->setText(QAction::tr("Ignore"));

    if(friendsList.contains(item->text(), Qt::CaseInsensitive))
        acFriend->setText(QAction::tr("Remove friend"));
    else
        acFriend->setText(QAction::tr("Add friend"));
}

void HWChatWidget::setShowReady(bool s)
{
    showReady = s;
}

void HWChatWidget::setReadyStatus(const QString & nick, bool isReady)
{
    QList<QListWidgetItem *> items = chatNicks->findItems(nick, Qt::MatchExactly);
    if (items.size() != 1)
    {
        qWarning("Bug: cannot find user in chat");
        return;
    }

    items[0]->setData(Qt::UserRole, isReady); // bulb status
    updateIcon(items[0]);

    // ensure we're still showing the status bulbs
    showReady = true;
}

void HWChatWidget::adminAccess(bool b)
{
    chatNicks->removeAction(acKick);
    chatNicks->removeAction(acBan);

    if(b)
    {
        chatNicks->insertAction(0, acKick);
//      chatNicks->insertAction(0, acBan);
    }
}
