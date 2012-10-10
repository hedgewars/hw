/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
#include <QTextDocument>
#include <QFile>
#include <QList>
#include <QSettings>
#include <QTextStream>
#include <QMenu>
#include <QCursor>
#include <QScrollBar>
#include <QItemSelectionModel>
#include <QStringList>
#include <QDateTime>
#include <QTime>
#include <QPainter>
#include <QListView>
#include <QMessageBox>
#include <QModelIndexList>
#include <QDebug>
#include <QSortFilterProxyModel>
#include <QMenu>

#include "DataManager.h"
#include "hwconsts.h"
#include "gameuiconfig.h"
#include "playerslistmodel.h"

#include "chatwidget.h"


ListWidgetNickItem::ListWidgetNickItem(const QString& nick, bool isFriend, bool isIgnored) : QListWidgetItem(nick)
{
    setData(Friend, isFriend);
    setData(Ignore, isIgnored);
}

void ListWidgetNickItem::setData(StateFlag role, const QVariant &value)
{
    QListWidgetItem::setData(role, value);

    updateIcon();
}

bool ListWidgetNickItem::operator< (const QListWidgetItem & other) const
{
    // case in-sensitive comparison of the associated strings
    // chars that are no letters are sorted at the end of the list

    ListWidgetNickItem otherNick = const_cast<ListWidgetNickItem &>(dynamic_cast<const ListWidgetNickItem &>(other));

    // ignored always down
    if (data(Ignore).toBool() != otherNick.data(Ignore).toBool())
        return !data(Ignore).toBool();

    // friends always up
    if (data(Friend).toBool() != otherNick.data(Friend).toBool())
        return data(Friend).toBool();

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

void ListWidgetNickItem::updateIcon()
{
    quint32 iconNum = 0;

    QList<bool> flags;
    flags
        << data(Ready).toBool()
        << data(ServerAdmin).toBool()
        << data(RoomAdmin).toBool()
        << data(Registered).toBool()
        << data(Friend).toBool()
        << data(Ignore).toBool()
        ;

    for(int i = flags.size() - 1; i >= 0; --i)
        if(flags[i])
            iconNum |= 1 << i;

    if(m_icons().contains(iconNum))
    {
        setIcon(m_icons().value(iconNum));
    }
    else
    {
        QPixmap result(24, 16);
        result.fill(Qt::transparent);

        QPainter painter(&result);

        if(data(Ready).toBool())
            painter.drawPixmap(0, 0, 16, 16, QPixmap(":/res/chat/lamp.png"));

        QString mainIconName(":/res/chat/");

        if(data(RoomAdmin).toBool())
            mainIconName += "roomadmin";
        else if(data(ServerAdmin).toBool())
            mainIconName += "serveradmin";
        else
            mainIconName += "hedgehog";

        if(!data(Registered).toBool())
            mainIconName += "_gray";

        painter.drawPixmap(8, 0, 16, 16, QPixmap(mainIconName + ".png"));

        if(data(Ignore).toBool())
            painter.drawPixmap(8, 0, 16, 16, QPixmap(":/res/chat/ignore.png"));
        else
        if(data(Friend).toBool())
            painter.drawPixmap(8, 0, 16, 16, QPixmap(":/res/chat/friend.png"));

        painter.end();

        QIcon icon(result);

        setIcon(icon);
        m_icons().insert(iconNum, icon);
    }

    if(data(Ignore).toBool())
        setForeground(Qt::gray);
    else
    if(data(Friend).toBool())
        setForeground(Qt::green);
    else
        setForeground(QBrush(QColor(0xff, 0xcc, 0x00)));
}

QHash<quint32, QIcon> & ListWidgetNickItem::m_icons()
{
    static QHash<quint32, QIcon> iconsCache;

    return iconsCache;
}

QString * HWChatWidget::s_styleSheet = NULL;
QStringList * HWChatWidget::s_displayNone = NULL;
bool HWChatWidget::s_isTimeStamped = true;
QString HWChatWidget::s_tsFormat = ":mm:ss";

const QString & HWChatWidget::styleSheet()
{
    if (s_styleSheet != NULL)
        return *s_styleSheet;

    setStyleSheet();

    return *s_styleSheet;
}

void HWChatWidget::setStyleSheet(const QString & styleSheet)
{
    QString orgStyleSheet = styleSheet;
    QString style = QString(orgStyleSheet);

    // no stylesheet supplied, search for one or use default
    if (orgStyleSheet.isEmpty())
    {
        // load external stylesheet if there is any
        QFile extFile(DataManager::instance().findFileForRead("css/chat.css"));

        QFile resFile(":/res/css/chat.css");

        QFile & file = (extFile.exists()?extFile:resFile);

        if (file.open(QIODevice::ReadOnly | QIODevice::Text))
        {
            QTextStream in(&file);
            while (!in.atEnd())
            {
                style.append(in.readLine()+"\n");
            }
            orgStyleSheet = style;

            file.close();
        }
    }

    // let's parse display:none; ...

    // prepare for MAGIC :D

    // matches (multi-)whitespaces (for replacement with simple space)
    QRegExp ws("\\s+");

    // matches comments (for removal)
    QRegExp rem("/\\*([^*]|\\*(?!/))*\\*/");

    // strip comments and multi-whitespaces to compress the style-sheet a bit
    style = style.remove(rem).replace(ws," ");


    // now let's see what messages the user does not want to be displayed
    // by checking for display:none; (since QTextBrowser does not support it)

    // MOAR MAGIC :DDD

    // matches definitions lacking display:none; (for removal)
    QRegExp displayed(
        "([^{}]*\\{)(?!([^}]*;)* ?display ?: ?none ?(;[^}]*)?\\})[^}]*\\}");

    // matches all {...} and , (used as seperator for splitting into names)
    QRegExp split(" *(\\{[^}]*\\}|,) *");

    // matches class names that are referenced without hierachy
    QRegExp nohierarchy("^.[^ .]+$");

    QStringList victims = QString(style).
                          remove(displayed). // remove visible stuff
                          trimmed().
                          split(split). // get a list of the names
                          filter(nohierarchy). // only direct class names
                          replaceInStrings(QRegExp("^."),""); // crop .


    if (victims.contains("timestamp"))
    {
        s_isTimeStamped = false;
        victims.removeAll("timestamp");
    }
    else
    {
        s_isTimeStamped = true;
        s_tsFormat =
            ((victims.contains("timestamp:hours"))?"":"hh:") +
            QString("mm") +
            ((victims.contains("timestamp:seconds"))?"":":ss");
    }

    victims.removeAll("timestamp:hours");
    victims.removeAll("timestamp:seconds");

    victims.removeDuplicates();

    QStringList * oldDisplayNone = s_displayNone;
    QString * oldStyleSheet = s_styleSheet;

    s_displayNone = new QStringList(victims);
    s_styleSheet = new QString(orgStyleSheet);

    if (oldDisplayNone != NULL)
        delete oldDisplayNone;

    if (oldStyleSheet != NULL)
        delete oldStyleSheet;

}

void HWChatWidget::displayError(const QString & message)
{
    addLine("msg_Error", " !!! " + message);
    // scroll to the end
    chatText->moveCursor(QTextCursor::End);
}


void HWChatWidget::displayNotice(const QString & message)
{
    addLine("msg_Notice", " *** " + message);
    // scroll to the end
    chatText->moveCursor(QTextCursor::End);
}


void HWChatWidget::displayWarning(const QString & message)
{
    addLine("msg_Warning", " *!* " + message);
    // scroll to the end
    chatText->moveCursor(QTextCursor::End);
}


HWChatWidget::HWChatWidget(QWidget* parent, QSettings * gameSettings, bool notify) :
    QWidget(parent),
    mainLayout(this)
{
    this->gameSettings = gameSettings;
    this->notify = notify;

    m_isAdmin = false;
    m_autoKickEnabled = false;

    if(gameSettings->value("frontend/sound", true).toBool())
    {
        QStringList vpList =
             QStringList() << "Classic" << "Default" << "Mobster" << "Russian";

        foreach (QString vp, vpList)
        {
            m_helloSounds.append(DataManager::instance().findFileForRead(
                               QString("Sounds/voices/%1/Hello.ogg").arg(vp)));
        }

        m_hilightSound = DataManager::instance().findFileForRead(
                             "Sounds/beep.ogg");

    }

    mainLayout.setSpacing(1);
    mainLayout.setMargin(1);
    mainLayout.setSizeConstraint(QLayout::SetMinimumSize);
    mainLayout.setColumnStretch(0, 76);
    mainLayout.setColumnStretch(1, 24);

    chatEditLine = new SmartLineEdit(this);
    chatEditLine->setMaxLength(300);
    connect(chatEditLine, SIGNAL(returnPressed()), this, SLOT(returnPressed()));

    mainLayout.addWidget(chatEditLine, 2, 0);

    chatText = new QTextBrowser(this);

    chatText->document()->setDefaultStyleSheet(styleSheet());

    chatText->setMinimumHeight(20);
    chatText->setMinimumWidth(10);
    chatText->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    chatText->setOpenLinks(false);
    connect(chatText, SIGNAL(anchorClicked(const QUrl&)),
            this, SLOT(linkClicked(const QUrl&)));
    mainLayout.addWidget(chatText, 0, 0, 2, 1);

    chatNicks = new QListView(this);
    chatNicks->setIconSize(QSize(24, 16));
    chatNicks->setSelectionMode(QAbstractItemView::SingleSelection);
    chatNicks->setEditTriggers(QAbstractItemView::NoEditTriggers);
    chatNicks->setMinimumHeight(10);
    chatNicks->setMinimumWidth(10);
    chatNicks->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    chatNicks->setContextMenuPolicy(Qt::CustomContextMenu);

    connect(chatNicks, SIGNAL(itemDoubleClicked(QListWidgetItem *)),
            this, SLOT(chatNickDoubleClicked(QListWidgetItem *)));

    connect(chatNicks, SIGNAL(customContextMenuRequested(QPoint)), this, SLOT(nicksContextMenuRequested(QPoint)));

    mainLayout.addWidget(chatNicks, 0, 1, 3, 1);

    // the userData is used to flag things that are even available when user
    // is offline
    acInfo = new QAction(QAction::tr("Info"), chatNicks);
    acInfo->setIcon(QIcon(":/res/info.png"));
    acInfo->setData(QVariant(false));
    connect(acInfo, SIGNAL(triggered(bool)), this, SLOT(onInfo()));
    acKick = new QAction(QAction::tr("Kick"), chatNicks);
    acKick->setIcon(QIcon(":/res/kick.png"));
    acKick->setData(QVariant(false));
    connect(acKick, SIGNAL(triggered(bool)), this, SLOT(onKick()));
    acBan = new QAction(QAction::tr("Ban"), chatNicks);
    acBan->setIcon(QIcon(":/res/ban.png"));
    acBan->setData(QVariant(true));
    connect(acBan, SIGNAL(triggered(bool)), this, SLOT(onBan()));
    acFollow = new QAction(QAction::tr("Follow"), chatNicks);
    acFollow->setIcon(QIcon(":/res/follow.png"));
    acFollow->setData(QVariant(false));
    connect(acFollow, SIGNAL(triggered(bool)), this, SLOT(onFollow()));
    acIgnore = new QAction(QAction::tr("Ignore"), chatNicks);
    acIgnore->setIcon(QIcon(":/res/ignore.png"));
    acIgnore->setData(QVariant(true));
    connect(acIgnore, SIGNAL(triggered(bool)), this, SLOT(onIgnore()));
    acFriend = new QAction(QAction::tr("Add friend"), chatNicks);
    acFriend->setIcon(QIcon(":/res/addfriend.png"));
    acFriend->setData(QVariant(true));
    connect(acFriend, SIGNAL(triggered(bool)), this, SLOT(onFriend()));

    chatNicks->insertAction(0, acFriend);
    chatNicks->insertAction(0, acInfo);
    chatNicks->insertAction(0, acIgnore);

    setShowFollow(true);

    setAcceptDrops(true);

    m_nicksMenu = new QMenu(this);

    clear();
}


void HWChatWidget::linkClicked(const QUrl & link)
{
    if (link.scheme() == "http")
        QDesktopServices::openUrl(link);
    if (link.scheme() == "hwnick")
    {
        // decode nick
        QString nick = QString::fromUtf8(QByteArray::fromBase64(link.encodedQuery()));
        /*QList<QListWidgetItem *> items = chatNicks->findItems(nick, Qt::MatchExactly);

        bool isOffline = (items.size() < 1);

        QMenu * popup = new QMenu(this);

        if (isOffline)
        {
            m_clickedNick = nick;
            chatNickSelected(0); // update friend and ignore entry
            chatNicks->setCurrentItem(NULL, QItemSelectionModel::Clear);
        }
        else
        {
            // selecting an item will automatically scroll there, so let's save old position
            QScrollBar * scrollBar = chatNicks->verticalScrollBar();
            int oldScrollPos = scrollBar->sliderPosition();
            // select the nick which we want to see the actions for
            chatNicks->setCurrentItem(items[0], QItemSelectionModel::Clear);
            // selecting an item will automatically scroll there, so let's save old position
            scrollBar->setSliderPosition(oldScrollPos);
        }

        // load actions
        QList<QAction *> actions = chatNicks->actions();

        foreach(QAction * action, actions)
        {
            if ((!isOffline) || (action->data().toBool()))
                popup->addAction(action);
        }

        // display menu popup at mouse cursor position
        popup->popup(QCursor::pos());*/
    }
}

void HWChatWidget::setShowFollow(bool enabled)
{
    if (enabled)
    {
        if (!(chatNicks->actions().contains(acFollow)))
            chatNicks->insertAction(acFriend, acFollow);
    }
    else
    {
        if (chatNicks->actions().contains(acFollow))
            chatNicks->removeAction(acFollow);
    }
}

void HWChatWidget::setIgnoreListKick(bool enabled)
{
    m_autoKickEnabled = enabled;
}

void HWChatWidget::loadList(QStringList & list, const QString & file)
{
    list.clear();
    QFile txt(cfgdir->absolutePath() + "/" + file);
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
    QFile txt(cfgdir->absolutePath() + "/" + file);

    // list empty? => rather have no file for the list than an empty one
    if (list.isEmpty())
    {
        if (txt.exists())
        {
            // try to remove file, if successful we're done here.
            if (txt.remove())
                return;
        }
        else
            // there is no file
            return;
    }

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

    item->setData(ListWidgetNickItem::Friend, QVariant(friendsList.contains(nick, Qt::CaseInsensitive)));
    item->setData(ListWidgetNickItem::Ignore, QVariant(ignoreList.contains(nick, Qt::CaseInsensitive)));
}

void HWChatWidget::updateNickItems()
{
    /*for(int i = 0; i < chatNicks->count(); i++)
        updateNickItem(chatNicks->item(i));

    chatNicks->sortItems();*/
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
    QStringList lines = chatEditLine->text().split('\n');
    chatEditLine->rememberCurrentText();
    foreach (const QString &line, lines)
    {
        // skip empty/whitespace lines
        if (line.trimmed().isEmpty())
            continue;

        if (!parseCommand(line))
            emit chatLine(line);
    }
    chatEditLine->clear();
}

// "link" nick, but before that encode it in base64 to make sure it can't
// intefere with html/url syntax the nick is put as querystring as putting
// it as host would convert it to it's lower case variant
QString HWChatWidget::linkedNick(const QString & nickname)
{
    if (nickname != m_userNick)
        return QString("<a href=\"hwnick://?%1\" class=\"nick\">%2</a>").arg(
                   QString(nickname.toUtf8().toBase64())).arg(Qt::escape(nickname));

    // unlinked nick (if own one)
    return QString("<span class=\"nick\">%1</span>").arg(Qt::escape(nickname));
}


void HWChatWidget::onChatString(const QString& str)
{
    onChatString("", str);
}

const QRegExp HWChatWidget::URLREGEXP = QRegExp("(http://)?(www\\.)?(hedgewars\\.org(/[^ ]*)?)");

void HWChatWidget::onChatString(const QString& nick, const QString& str)
{
    bool isFriend = false;

    if (!nick.isEmpty())
    {
        // don't show chat lines that are from ignored nicks
        if (ignoreList.contains(nick, Qt::CaseInsensitive))
            return;
        // friends will get special treatment, of course
        isFriend = friendsList.contains(nick, Qt::CaseInsensitive);
    }

    QString formattedStr = Qt::escape(str.mid(1));
    // make hedgewars.org urls actual links
    formattedStr = formattedStr.replace(URLREGEXP, "<a href=\"http://\\3\">\\3</a>");

    // link the nick
    if(!nick.isEmpty())
        formattedStr.replace("|nick|", linkedNick(nick));

    QString cssClass("msg_UserChat");

    // check first character for color code and set color properly
    char c = str[0].toAscii();
    switch (c)
    {
        case 3:
            cssClass = (isFriend ? "msg_FriendJoin" : "msg_UserJoin");
            break;
        case 2:
            cssClass = (isFriend ? "msg_FriendAction" : "msg_UserAction");
            break;
        default:
            if (isFriend)
                cssClass = "msg_FriendChat";
    }

    bool isHL = false;

    if ((c != 3) && (!nick.isEmpty()) &&
            (nick != m_userNick) && (!m_userNick.isEmpty()))
    {
        QString lcStr = str.toLower();

        foreach (const QRegExp & hl, m_highlights)
        {
            if (lcStr.contains(hl))
            {
                isHL = true;
                break;
            }
        }
    }

    addLine(cssClass, formattedStr, isHL);
}

void HWChatWidget::addLine(const QString & cssClass, QString line, bool isHighlight)
{
    if (s_displayNone->contains(cssClass))
        return; // the css forbids us to display this line

    if (chatStrings.size() > 250)
        chatStrings.removeFirst();

    if (s_isTimeStamped)
    {
        QString tsMarkUp = "<span class=\"timestamp\">[%1]</span> ";
        QTime now = QDateTime::currentDateTime().time();
        line = tsMarkUp.arg(now.toString(s_tsFormat)) + line;
    }

    line = QString("<span class=\"%1\">%2</span>").arg(cssClass).arg(line);

    if (isHighlight)
    {
        line = QString("<span class=\"highlight\">%1</span>").arg(line);
        SDLInteraction::instance().playSoundFile(m_hilightSound);
    }

    chatStrings.append(line);

    chatText->setHtml("<html><body>"+chatStrings.join("<br>")+"</body></html>");

    chatText->moveCursor(QTextCursor::End);
}

void HWChatWidget::onServerMessage(const QString& str)
{
    if (chatStrings.size() > 250)
        chatStrings.removeFirst();

    chatStrings.append("<hr>" + str + "<hr>");

    chatText->setHtml("<html><body>"+chatStrings.join("<br>")+"</body></html>");

    chatText->moveCursor(QTextCursor::End);
}

void HWChatWidget::nickAdded(const QString & nick, bool notifyNick)
{
    bool isIgnored = ignoreList.contains(nick, Qt::CaseInsensitive);

    if (isIgnored && m_isAdmin && m_autoKickEnabled)
    {
        emit kick(nick);
        return;
    }

    QListWidgetItem * item = new ListWidgetNickItem(nick, friendsList.contains(nick, Qt::CaseInsensitive), isIgnored);
    updateNickItem(item);
    /*chatNicks->addItem(item);*/

    if ((!isIgnored) && (nick != m_userNick)) // don't auto-complete own name
        chatEditLine->addNickname(nick);

    emit nickCountUpdate(chatNicks->model()->rowCount());

    if(notifyNick && notify && gameSettings->value("frontend/sound", true).toBool())
    {
        SDLInteraction::instance().playSoundFile(
                            m_helloSounds.at(rand() % m_helloSounds.size()));
    }
}

void HWChatWidget::nickRemoved(const QString& nick)
{
    chatEditLine->removeNickname(nick);

    /*foreach(QListWidgetItem * item, chatNicks->findItems(nick, Qt::MatchExactly))
        chatNicks->takeItem(chatNicks->row(item));*/

    //emit nickCountUpdate(chatNicks->count());
}

void HWChatWidget::clear()
{
    chatEditLine->reset();

    // add default commands
    QStringList cmds;
    cmds << "/me" << "/discardStyleSheet" << "/saveStyleSheet";
    chatEditLine->addCommands(cmds);

    chatText->clear();
    chatStrings.clear();
    //chatNicks->clear();

    // clear and re compile regexp for highlighting
    m_highlights.clear();

    QString hlRegExp("^(.* )?%1[^-a-z0-9_]*( .*)?$");
    QRegExp whitespace("\\s");

    m_highlights.append(QRegExp(hlRegExp.arg(m_userNick)));

    QFile file(cfgdir->absolutePath() + "/" + m_userNick + "_highlight.txt");

    if (file.exists() && (file.open(QIODevice::ReadOnly | QIODevice::Text)))
    {
        QTextStream in(&file);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            QStringList list = line.split(whitespace);
            foreach (QString word, list)
            {
                m_highlights.append(QRegExp(
                                        hlRegExp.arg(QRegExp::escape(word.toLower()))));
            }
        }

        if (file.isOpen())
            file.close();
    }

    QFile file2(cfgdir->absolutePath() + "/" + m_userNick + "_hlregexp.txt");

    if (file2.exists() && (file2.open(QIODevice::ReadOnly | QIODevice::Text)))
    {
        QTextStream in(&file2);
        while (!in.atEnd())
        {
            m_highlights.append(QRegExp(in.readLine().toLower()));
        }

        if (file2.isOpen())
            file2.close();
    }
}

void HWChatWidget::onKick()
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    if(mil.size())
        emit kick(mil[0].data().toString());
}

void HWChatWidget::onBan()
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    if(mil.size())
        emit ban(mil[0].data().toString());
}

void HWChatWidget::onInfo()
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    if(mil.size())
        emit info(mil[0].data().toString());
}

void HWChatWidget::onFollow()
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    if(mil.size())
        emit follow(mil[0].data().toString());
}

void HWChatWidget::onIgnore()
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    QString nick;
    if(mil.size())
        nick = mil[0].data().toString();
    else
        nick = m_clickedNick;

    QSortFilterProxyModel * playersSortFilterModel = qobject_cast<QSortFilterProxyModel *>(chatNicks->model());
    if(!playersSortFilterModel)
        return;

    PlayersListModel * players = qobject_cast<PlayersListModel *>(playersSortFilterModel->sourceModel());

    if(!players)
        return;

    if(players->isFlagSet(nick, PlayersListModel::Ignore))
    {
        players->setFlag(nick, PlayersListModel::Ignore, false);
        chatEditLine->addNickname(nick);
        displayNotice(tr("%1 has been removed from your ignore list").arg(linkedNick(nick)));
    }
    else // not on list - add
    {
        // don't consider ignored people friends
        if(players->isFlagSet(nick, PlayersListModel::Friend))
            emit onFriend();

        players->setFlag(nick, PlayersListModel::Ignore, true);
        chatEditLine->removeNickname(nick);
        displayNotice(tr("%1 has been added to your ignore list").arg(linkedNick(nick)));
    }

    if(mil.size())
    {
        chatNicks->scrollTo(chatNicks->selectionModel()->selectedRows()[0]);
        chatNickSelected(); // update context menu
    }
}

void HWChatWidget::onFriend()
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    QString nick;
    if(mil.size())
        nick = mil[0].data().toString();
    else
        nick = m_clickedNick;

    QSortFilterProxyModel * playersSortFilterModel = qobject_cast<QSortFilterProxyModel *>(chatNicks->model());
    if(!playersSortFilterModel)
        return;

    PlayersListModel * players = qobject_cast<PlayersListModel *>(playersSortFilterModel->sourceModel());

    if(!players)
        return;

    if(players->isFlagSet(nick, PlayersListModel::Friend))
    {
        players->setFlag(nick, PlayersListModel::Friend, false);
        chatEditLine->removeNickname(nick);
        displayNotice(tr("%1 has been removed from your friends list").arg(linkedNick(nick)));
    }
    else // not on list - add
    {
        if(players->isFlagSet(nick, PlayersListModel::Ignore))
            emit onIgnore();

        players->setFlag(nick, PlayersListModel::Friend, true);
        chatEditLine->addNickname(nick);
        displayNotice(tr("%1 has been added to your friends list").arg(linkedNick(nick)));
    }

    if(mil.size())
    {
        chatNicks->scrollTo(chatNicks->selectionModel()->selectedRows()[0]);
        chatNickSelected(); // update context menu
    }
}

void HWChatWidget::chatNickDoubleClicked(QListWidgetItem * item)
{
    if (item != NULL)
        m_clickedNick = item->text();
    else
        m_clickedNick = "";
    QList<QAction *> actions = chatNicks->actions();
    actions.first()->activate(QAction::Trigger);
}

void HWChatWidget::chatNickSelected()
{
}

void HWChatWidget::setStatus(const QString & nick, ListWidgetNickItem::StateFlag flag, bool status)
{
    /*QList<QListWidgetItem *> items = chatNicks->findItems(nick, Qt::MatchExactly);

    if (items.size() == 1)
    {
        items[0]->setData(flag, status);
        updateNickItem(items[0]);
    }*/
}

void HWChatWidget::setReadyStatus(const QString & nick, bool isReady)
{
    setStatus(nick, ListWidgetNickItem::Ready, isReady);
}

void HWChatWidget::setAdminStatus(const QString & nick, bool isAdmin)
{
    setStatus(nick, ListWidgetNickItem::ServerAdmin, isAdmin);
}

void HWChatWidget::setRoomMasterStatus(const QString & nick, bool isAdmin)
{
    setStatus(nick, ListWidgetNickItem::RoomAdmin, isAdmin);
}

void HWChatWidget::setRegisteredStatus(const QStringList & nicks, bool isRegistered)
{
    foreach(const QString & nick, nicks)
        setStatus(nick, ListWidgetNickItem::Registered, isRegistered);
}

void HWChatWidget::adminAccess(bool b)
{
    chatNicks->removeAction(acKick);
    chatNicks->removeAction(acBan);

    m_isAdmin = b;

    if(b)
    {
        chatNicks->insertAction(0, acKick);
        chatNicks->insertAction(0, acBan);
    }
}

void HWChatWidget::dragEnterEvent(QDragEnterEvent * event)
{
    if (event->mimeData()->hasUrls())
    {
        QList<QUrl> urls = event->mimeData()->urls();
        if (urls.count() == 1)
        {
            QUrl url = urls[0];

            static QRegExp localFileRegExp("file://.*\\.css$");
            localFileRegExp.setCaseSensitivity(Qt::CaseInsensitive);

            if (url.toString().contains(localFileRegExp))
                event->acceptProposedAction();
        }
    }
}

void HWChatWidget::dropEvent(QDropEvent * event)
{
    const QString path(event->mimeData()->urls()[0].toString());

    QFile file(event->mimeData()->urls()[0].toLocalFile());

    if (file.exists() && (file.open(QIODevice::ReadOnly | QIODevice::Text)))
    {
        QString style;
        QTextStream in(&file);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            style.append(line + "\n");
        }

        setStyleSheet(style);
        chatText->document()->setDefaultStyleSheet(*s_styleSheet);
        displayNotice(tr("Stylesheet imported from %1").arg(path));
        displayNotice(tr("Enter %1 if you want to use the current StyleSheet in future, enter %2 to reset!").arg("/saveStyleSheet").arg("/discardStyleSheet"));

        if (file.isOpen())
            file.close();

        event->acceptProposedAction();
    }
    else
        displayError(tr("Couldn't read %1").arg(event->mimeData()->urls()[0].toString()));
}


void HWChatWidget::discardStyleSheet()
{
    setStyleSheet();
    chatText->document()->setDefaultStyleSheet(*s_styleSheet);
    displayNotice(tr("StyleSheet discarded"));
}


void HWChatWidget::saveStyleSheet()
{
    QString dest =
        DataManager::instance().findFileForWrite("css/chat.css");

    QFile file(dest);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        QTextStream out(&file);
        QStringList lines = s_styleSheet->split("\n", QString::KeepEmptyParts);

        // strip trailing empty lines
        while (lines.last().isEmpty())
            lines.takeLast();

        foreach (const QString & line, lines)
        {
            out << line << endl;
        }
        out << endl;
        file.close();
        displayNotice(tr("StyleSheet saved to %1").arg(dest));
    }
    else
        displayError(tr("Failed to save StyleSheet to %1").arg(dest));
}


bool HWChatWidget::parseCommand(const QString & line)
{
    if (line[0] == '/')
    {
        QString tline = line.trimmed();
        if (tline.startsWith("/me"))
            return false; // not a real command

        else if (tline == "/discardStyleSheet")
            discardStyleSheet();
        else if (tline == "/saveStyleSheet")
            saveStyleSheet();
        else
        {
            static QRegExp post("\\s.*$");
            tline.remove(post);
            displayWarning(tr("%1 is not a valid command!").arg(tline));
        }

        return true;
    }

    return false;
}


void HWChatWidget::setUser(const QString & nickname)
{
    m_userNick = nickname;
    nickRemoved(nickname);
    clear();
}


void HWChatWidget::setUsersModel(QAbstractItemModel *model)
{
    chatNicks->selectionModel()->deleteLater();

    chatNicks->setModel(model);
    chatNicks->setModelColumn(0);

    connect(chatNicks->selectionModel(), SIGNAL(currentRowChanged(QModelIndex,QModelIndex)),
            this, SLOT(chatNickSelected()));
}

void HWChatWidget::nicksContextMenuRequested(const QPoint &pos)
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    QString nick;

    if(mil.size())
        nick = mil[0].data().toString();
    else
        nick = m_clickedNick;

    QSortFilterProxyModel * playersSortFilterModel = qobject_cast<QSortFilterProxyModel *>(chatNicks->model());
    if(!playersSortFilterModel)
        return;

    PlayersListModel * players = qobject_cast<PlayersListModel *>(playersSortFilterModel->sourceModel());

    if(!players)
        return;

    bool isSelf = (nick == m_userNick);

    acFollow->setVisible(!isSelf);

    // update context menu labels according to possible action
    if(players->isFlagSet(nick, PlayersListModel::Ignore))
    {
        acIgnore->setText(QAction::tr("Unignore"));
        acIgnore->setIcon(QIcon(":/res/unignore.png"));
    }
    else
    {
        acIgnore->setText(QAction::tr("Ignore"));
        acIgnore->setIcon(QIcon(":/res/ignore.png"));
        acIgnore->setVisible(!isSelf);
    }

    if(players->isFlagSet(nick, PlayersListModel::Friend))
    {
        acFriend->setText(QAction::tr("Remove friend"));
        acFriend->setIcon(QIcon(":/res/remfriend.png"));
    }
    else
    {
        acFriend->setText(QAction::tr("Add friend"));
        acFriend->setIcon(QIcon(":/res/addfriend.png"));
        acFriend->setVisible(!isSelf);
    }

    if (m_isAdmin)
    {
        acKick->setVisible(!isSelf);
        acBan->setVisible(!isSelf);
    }

    m_nicksMenu->clear();

    foreach(QAction * action, chatNicks->actions())
        m_nicksMenu->addAction(action);

    m_nicksMenu->popup(chatNicks->mapToGlobal(pos));
}
