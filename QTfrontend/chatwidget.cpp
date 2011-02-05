/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2010 Andrey Korotaev <unC0Rr@gmail.com>
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

#include <QDesktopServices>
#include <QTextBrowser>
#include <QLineEdit>
#include <QAction>
#include <QApplication>
#include <QTextDocument>
#include <QDir>
#include <QSettings>
#include <QFile>
#include <QTextStream>
#include <QMenu>
#include <QCursor>
#include <QScrollBar>
#include <QItemSelectionModel>

#include "hwconsts.h"
#include "SDLs.h"
#include "gameuiconfig.h"
#include "chatwidget.h"

ListWidgetNickItem::ListWidgetNickItem(const QString& nick, bool isFriend, bool isIgnored) : QListWidgetItem(nick)
{
    this->aFriend = isFriend;
    this->isIgnored = isIgnored;
}

void ListWidgetNickItem::setFriend(bool isFriend)
{
    this->aFriend = isFriend;
}

void ListWidgetNickItem::setIgnored(bool isIgnored)
{
    this->isIgnored = isIgnored;
}

bool ListWidgetNickItem::isFriend()
{
    return aFriend;
}

bool ListWidgetNickItem::ignored()
{
    return isIgnored;
}

bool ListWidgetNickItem::operator< (const QListWidgetItem & other) const
{
    // case in-sensitive comparison of the associated strings
    // chars that are no letters are sorted at the end of the list

    ListWidgetNickItem otherNick = const_cast<ListWidgetNickItem &>(dynamic_cast<const ListWidgetNickItem &>(other));

    // ignored always down
    if (isIgnored != otherNick.ignored())
        return !isIgnored;

    // friends always up
    if (aFriend != otherNick.isFriend())
        return aFriend;

    QString txt1 = text().toLower();
    QString txt2 = other.text().toLower();

    bool firstIsShorter = (txt1.size() < txt2.size());
    int len = firstIsShorter?txt1.size():txt2.size();

    for (int i = 0; i < len; i++)
    {
        if (txt1[i] == txt2[i])
            continue;
        if (txt1[i].isLetter() != txt2[i].isLetter())
            return txt1[i].isLetter();
        return (txt1[i] < txt2[i]);
    }

    return firstIsShorter;
}

const char* HWChatWidget::STYLE = 
"\
a { color:#c8c8ff; }\
.nick { text-decoration: none; }\
.UserChat .nick { color:#ffec20; }\
.FriendChat { color: #08e008; }\
.FriendChat .nick { color: #20ff20; }\
.UserJoin { color: #c0c0c0; }\
.UserJoin .nick { color: #d0d0d0; }\
.FriendJoin { color: #c0e0c0; }\
.FriendJoin .nick { color: #d0f0d0; }\
.UserAction { color: #ff80ff; }\
.UserAction .nick { color: #ffa0ff; }\
.FriendAction { color: #ff00ff; }\
.FriendAction .nick { color: #ff30ff; }\
";

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
    mainLayout.setColumnStretch(0, 76);
    mainLayout.setColumnStretch(1, 24);

    chatEditLine = new QLineEdit(this);
    chatEditLine->setMaxLength(300);
    connect(chatEditLine, SIGNAL(returnPressed()), this, SLOT(returnPressed()));

    mainLayout.addWidget(chatEditLine, 1, 0);

    chatText = new QTextBrowser(this);
    chatText->document()->setDefaultStyleSheet(STYLE);
    chatText->setMinimumHeight(20);
    chatText->setMinimumWidth(10);
    chatText->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    chatText->setOpenLinks(false);
    connect(chatText, SIGNAL(anchorClicked(const QUrl&)),
        this, SLOT(linkClicked(const QUrl&)));
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

    mainLayout.addWidget(chatNicks, 0, 1, -1, 1);

    acInfo = new QAction(QAction::tr("Info"), chatNicks);
    acInfo->setIcon(QIcon(":/res/info.png"));
    connect(acInfo, SIGNAL(triggered(bool)), this, SLOT(onInfo()));
    acKick = new QAction(QAction::tr("Kick"), chatNicks);
    acKick->setIcon(QIcon(":/res/kick.png"));
    connect(acKick, SIGNAL(triggered(bool)), this, SLOT(onKick()));
    acBan = new QAction(QAction::tr("Ban"), chatNicks);
    acBan->setIcon(QIcon(":/res/ban.png"));
    connect(acBan, SIGNAL(triggered(bool)), this, SLOT(onBan()));
    acFollow = new QAction(QAction::tr("Follow"), chatNicks);
    acFollow->setIcon(QIcon(":/res/follow.png"));
    connect(acFollow, SIGNAL(triggered(bool)), this, SLOT(onFollow()));
    acIgnore = new QAction(QAction::tr("Ignore"), chatNicks);
    acIgnore->setIcon(QIcon(":/res/ignore.png"));
    connect(acIgnore, SIGNAL(triggered(bool)), this, SLOT(onIgnore()));
    acFriend = new QAction(QAction::tr("Add friend"), chatNicks);
    acFriend->setIcon(QIcon(":/res/addfriend.png"));
    connect(acFriend, SIGNAL(triggered(bool)), this, SLOT(onFriend()));

    chatNicks->insertAction(0, acFriend);
    chatNicks->insertAction(0, acInfo);
    chatNicks->insertAction(0, acIgnore);

    showReady = false;
    setShowFollow(true);
}

void HWChatWidget::linkClicked(const QUrl & link)
{
    if (link.scheme() == "http")
        QDesktopServices::openUrl(link);
    if (link.scheme() == "hwnick")
    {
        // decode nick
        const QString& nick = QString::fromUtf8(QByteArray::fromBase64(link.encodedQuery()));
        QList<QListWidgetItem *> items = chatNicks->findItems(nick, Qt::MatchExactly);
        if (items.size() < 1)
            return;
        QMenu * popup = new QMenu();
        // selecting an item will automatically scroll there, so let's save old position
        QScrollBar * scrollBar = chatNicks->verticalScrollBar();
        int oldScrollPos = scrollBar->sliderPosition();
        // select the nick which we want to see the actions for
        chatNicks->setCurrentItem(items[0], QItemSelectionModel::Clear);
        // selecting an item will automatically scroll there, so let's save old position
        scrollBar->setSliderPosition(oldScrollPos);
        // load actions
        popup->addActions(chatNicks->actions());
        // display menu popup at mouse cursor position
        popup->popup(QCursor::pos());
    }
}

void HWChatWidget::setShowFollow(bool enabled)
{
    if (enabled) {
        if (!(chatNicks->actions().contains(acFollow)))
            chatNicks->insertAction(acFriend, acFollow);
    }
    else {
        if (chatNicks->actions().contains(acFollow))
            chatNicks->removeAction(acFollow);
    }
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

void HWChatWidget::updateNickItem(QListWidgetItem *nickItem)
{
    QString nick = nickItem->text();
    ListWidgetNickItem * item = dynamic_cast<ListWidgetNickItem*>(nickItem);

    item->setFriend(friendsList.contains(nick, Qt::CaseInsensitive));
    item->setIgnored(ignoreList.contains(nick, Qt::CaseInsensitive));

    if(item->ignored())
    {
        item->setIcon(QIcon(showReady ? (item->data(Qt::UserRole).toBool() ? ":/res/chat_ignore_on.png" : ":/res/chat_ignore_off.png") : ":/res/chat_ignore.png"));
        item->setForeground(Qt::gray);
    }
    else if(item->isFriend())
    {
        item->setIcon(QIcon(showReady ? (item->data(Qt::UserRole).toBool() ? ":/res/chat_friend_on.png" : ":/res/chat_friend_off.png") : ":/res/chat_friend.png"));
        item->setForeground(Qt::green);
    }
    else
    {
        item->setIcon(QIcon(showReady ? (item->data(Qt::UserRole).toBool() ? ":/res/chat_default_on.png" : ":/res/chat_default_off.png") : ":/res/chat_default.png"));
        item->setForeground(QBrush(QColor(0xff, 0xcc, 0x00)));
    }
}

void HWChatWidget::updateNickItems()
{
    for(int i = 0; i < chatNicks->count(); i++)
        updateNickItem(chatNicks->item(i));

    chatNicks->sortItems();
}

void HWChatWidget::loadLists(const QString & nick)
{
    loadList(ignoreList, nick.toLower() + "_ignore.txt");
    loadList(friendsList, nick.toLower() + "_friends.txt");
    updateNickItems();
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
    onChatString("", str);
}

const QRegExp HWChatWidget::URLREGEXP = QRegExp("(http://)?(www\\.)?(hedgewars\\.org(/[^ ]*)?)");

void HWChatWidget::onChatString(const QString& nick, const QString& str)
{
    bool isFriend = false;

    if (!nick.isEmpty()) {
        // don't show chat lines that are from ignored nicks
        if (ignoreList.contains(nick, Qt::CaseInsensitive))
            return;
        // friends will get special treatment, of course
        isFriend = friendsList.contains(nick, Qt::CaseInsensitive);
    }

    if (chatStrings.size() > 250)
        chatStrings.removeFirst();

    QString formattedStr = Qt::escape(str.mid(1));
    // make hedgewars.org urls actual links
    formattedStr = formattedStr.replace(URLREGEXP, "<a href=\"http://\\3\">\\3</a>");

    // "link" nick, but before that encode it in base64 to make sure it can't intefere with html/url syntax
    // the nick is put as querystring as putting it as host would convert it to it's lower case variant
    if(!nick.isEmpty())
        formattedStr.replace("|nick|",QString("<a href=\"hwnick://?%1\" class=\"nick\">%2</a>").arg(QString(nick.toUtf8().toBase64())).arg(nick));

    QString cssClass("UserChat");

    // check first character for color code and set color properly
    switch (str[0].toAscii()) {
        case 3:
            cssClass = (isFriend ? "FriendJoin" : "UserJoin");
            break;
        case 2:
            cssClass = (isFriend ? "FriendAction" : "UserAction");
            break;
        default:
            if (isFriend)
                cssClass = "FriendChat";
    }

    formattedStr = QString("<span class=\"%2\">%1</span>").arg(formattedStr).arg(cssClass);

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
    QListWidgetItem * item = new ListWidgetNickItem(nick, friendsList.contains(nick, Qt::CaseInsensitive), ignoreList.contains(nick, Qt::CaseInsensitive));
    updateNickItem(item);
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
        // don't consider ignored people friends
        if(friendsList.contains(curritem->text(), Qt::CaseInsensitive))
            emit onFriend();

        // scroll down on first ignore added so that people see where that nick went to
        if (ignoreList.isEmpty())
            chatNicks->scrollToBottom();

        ignoreList << curritem->text().toLower();
        onChatString(HWChatWidget::tr("%1 *** %2 has been added to your ignore list").arg('\x03').arg(curritem->text()));
    }
    updateNickItem(curritem); // update icon/sort order/etc
    chatNicks->sortItems();
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
        // don't ignore the new friend
        if(ignoreList.contains(curritem->text(), Qt::CaseInsensitive))
            emit onIgnore();

        // scroll up on first friend added so that people see where that nick went to
        if (friendsList.isEmpty())
            chatNicks->scrollToTop();

        friendsList << curritem->text().toLower();
        onChatString(HWChatWidget::tr("%1 *** %2 has been added to your friends list").arg('\x03').arg(curritem->text()));
    }
    updateNickItem(curritem); // update icon/sort order/etc
    chatNicks->sortItems();
    chatNickSelected(0); // update context menu
}

void HWChatWidget::chatNickDoubleClicked(QListWidgetItem * item)
{
    Q_UNUSED(item);

    QList<QAction *> actions = chatNicks->actions();
    actions.first()->activate(QAction::Trigger);
}

void HWChatWidget::chatNickSelected(int index)
{
    Q_UNUSED(index);

    QListWidgetItem* item = chatNicks->currentItem();
    if (!item)
        return;

    // update context menu labels according to possible action
    if(ignoreList.contains(item->text(), Qt::CaseInsensitive))
    {
        acIgnore->setText(QAction::tr("Unignore"));
        acIgnore->setIcon(QIcon(":/res/unignore.png"));
    }
    else
    {
        acIgnore->setText(QAction::tr("Ignore"));
        acIgnore->setIcon(QIcon(":/res/ignore.png"));
    }

    if(friendsList.contains(item->text(), Qt::CaseInsensitive))
    {
        acFriend->setText(QAction::tr("Remove friend"));
        acFriend->setIcon(QIcon(":/res/remfriend.png"));
    }
    else
    {
        acFriend->setText(QAction::tr("Add friend"));
        acFriend->setIcon(QIcon(":/res/addfriend.png"));
    }
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
    updateNickItem(items[0]);

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
