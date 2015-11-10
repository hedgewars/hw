/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <QDesktopServices>
#include <QTextBrowser>
#include <QAction>
#include <QFile>
#include <QTextStream>
#include <QMenu>
#include <QCursor>
#include <QItemSelectionModel>
#include <QDateTime>
#include <QTime>
#include <QListView>
#include <QModelIndexList>
#include <QSortFilterProxyModel>
#include <QMenu>
#include <QScrollBar>

#include "DataManager.h"
#include "hwconsts.h"
#include "gameuiconfig.h"
#include "playerslistmodel.h"
#include "HWApplication.h"
#include "chatwidget.h"


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
        QFile extFile("physfs://css/chat.css");

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
}


void HWChatWidget::displayNotice(const QString & message)
{
    addLine("msg_Notice", " *** " + message);
}


void HWChatWidget::displayWarning(const QString & message)
{
    addLine("msg_Warning", " *!* " + message);
}


HWChatWidget::HWChatWidget(QWidget* parent, bool notify) :
    QWidget(parent),
    mainLayout(this)
{
    this->gameSettings = NULL;
    this->notify = notify;

    m_usersModel = NULL;

    m_isAdmin = false;
    m_autoKickEnabled = false;

    m_scrollToBottom = false;
    m_scrollBarPos = 0;

    QStringList vpList =
         QStringList() << "Classic" << "Default" << "Mobster" << "Russian";

    foreach (const QString & vp, vpList)
    {
        m_helloSounds.append(QString("/Sounds/voices/%1/Hello.ogg").arg(vp));
    }

    m_hilightSound = "/Sounds/beep.ogg";

    mainLayout.setMargin(0);

    QWidget * leftSideContainer = new QWidget();
    leftSideContainer->setObjectName("leftSideContainer");
    leftSideContainer->setStyleSheet("#leftSideContainer { border-width: 0px; background-color: #ffcc00; border-radius: 10px;} QTextBrowser, SmartLineEdit { background-color: rgb(13, 5, 68); }");
    QVBoxLayout * leftSide = new QVBoxLayout(leftSideContainer);
    leftSide->setSpacing(3);
    leftSide->setMargin(3);
    mainLayout.addWidget(leftSideContainer, 76);

    // Chat view

    chatText = new QTextBrowser(this);
    chatText->document()->setDefaultStyleSheet(styleSheet());
    chatText->setMinimumHeight(20);
    chatText->setMinimumWidth(10);
    chatText->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    chatText->setOpenLinks(false);
    chatText->setStyleSheet("QTextBrowser { background-color: rgb(23, 11, 54); border-width: 0px; }");
    connect(chatText, SIGNAL(anchorClicked(const QUrl&)),
            this, SLOT(linkClicked(const QUrl&)));
    leftSide->addWidget(chatText, 1);

    // Input box

    // Normal:  rgb(23, 11, 54)
    // Hover:   rgb(13, 5, 68)

    chatEditLine = new SmartLineEdit();
    chatEditLine->setMaxLength(300);
    chatEditLine->setStyleSheet("SmartLineEdit { background-color: rgb(23, 11, 54); padding: 2px 8px; border-width: 0px; border-radius: 7px; } SmartLineEdit:hover, SmartLineEdit:focus { background-color: rgb(13, 5, 68); }");
    chatEditLine->setFixedHeight(24);
    chatEditLine->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Fixed);
    connect(chatEditLine, SIGNAL(returnPressed()), this, SLOT(returnPressed()));

    leftSide->addWidget(chatEditLine, 0);

    // Nickname list

    chatNicks = new QListView(this);
    chatNicks->setIconSize(QSize(24, 16));
    chatNicks->setSelectionMode(QAbstractItemView::SingleSelection);
    chatNicks->setEditTriggers(QAbstractItemView::NoEditTriggers);
    chatNicks->setMinimumHeight(10);
    chatNicks->setMinimumWidth(10);
    chatNicks->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    chatNicks->setContextMenuPolicy(Qt::CustomContextMenu);

    connect(chatNicks, SIGNAL(doubleClicked(QModelIndex)),
            this, SLOT(chatNickDoubleClicked(QModelIndex)));

    connect(chatNicks, SIGNAL(customContextMenuRequested(QPoint)), this, SLOT(nicksContextMenuRequested(QPoint)));

    mainLayout.addSpacing(0);
    mainLayout.addWidget(chatNicks, 24);

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

void HWChatWidget::setSettings(QSettings * settings)
{
    gameSettings = settings;
}

void HWChatWidget::linkClicked(const QUrl & link)
{
    if ((link.scheme() == "http") or (link.scheme() == "https"))
        QDesktopServices::openUrl(link);
    else if (link.scheme() == "hwnick")
    {
        // decode nick
        QString nick = QString::fromUtf8(QByteArray::fromBase64(link.encodedQuery()));
        QModelIndexList mil = chatNicks->model()->match(chatNicks->model()->index(0, 0), Qt::DisplayRole, nick);

        bool isOffline = (mil.size() < 1);

        if (isOffline)
        {
            m_clickedNick = nick;
            chatNicks->selectionModel()->clearSelection();
        }
        else
        {
            chatNicks->selectionModel()->select(mil[0], QItemSelectionModel::ClearAndSelect);
        }

        nicksContextMenuRequested(chatNicks->mapFromGlobal(QCursor::pos()));
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

const QRegExp HWChatWidget::URLREGEXP = QRegExp("(http(s)?://)?(www\\.)?((hedgewars\\.org|code\\.google\\.com|googlecode\\.com|hh\\.unit22\\.org)(/[^ ]*)?)");

bool HWChatWidget::containsHighlight(const QString & sender, const QString & message)
{
    if ((sender != m_userNick) && (!m_userNick.isEmpty()))
    {
        QString lcStr = message.toLower();

        foreach (const QRegExp & hl, m_highlights)
        {
            if (lcStr.contains(hl))
                return true;
        }
    }
    return false;
}

QString HWChatWidget::messageToHTML(const QString & message)
{
    QString formattedStr = Qt::escape(message);
    // link some urls
    formattedStr = formattedStr.replace(URLREGEXP, "<a href=\"http\\2://\\4\">\\4</a>");
    return formattedStr;
}

void HWChatWidget::onChatAction(const QString & nick, const QString & action)
{
    printChatString(nick, "* " + linkedNick(nick) + " " + messageToHTML(action), "Action", containsHighlight(nick, action));
}

void HWChatWidget::onChatMessage(const QString & nick, const QString & message)
{
    printChatString(nick, linkedNick(nick) + ": " + messageToHTML(message), "Chat", containsHighlight(nick, message));
}

void HWChatWidget::printChatString(
    const QString & nick, const QString & str, const QString & cssClassPart, bool highlight)
{
    if(!m_usersModel)
        return;

    // don't show chat lines that are from ignored nicks
    if (m_usersModel->isFlagSet(nick, PlayersListModel::Ignore))
        return;

    bool isFriend = (!nick.isEmpty()) && m_usersModel->isFlagSet(nick, PlayersListModel::Friend);

    QString cssClass = (isFriend ? "msg_Friend" : "msg_User") + cssClassPart;

    addLine(cssClass, str, highlight);
}

bool HWChatWidget::isInGame() {
    if (!m_usersModel)
        return false;

    return m_usersModel->isFlagSet(m_userNick, PlayersListModel::InGame);
}

void HWChatWidget::addLine(const QString & cssClass, QString line, bool isHighlight)
{
    if (s_displayNone->contains(cssClass))
        return; // the css forbids us to display this line

    beforeContentAdd();

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
        if (!isInGame())
            HWApplication::alert(this, 800);
    }

    chatStrings.append(line);

    chatText->setHtml("<html><body>"+chatStrings.join("<br>")+"</body></html>");

    afterContentAdd();
}

void HWChatWidget::onServerMessage(const QString& str)
{
    beforeContentAdd();

    if (chatStrings.size() > 250)
        chatStrings.removeFirst();

    chatStrings.append("<hr>" + str + "<hr>");

    chatText->setHtml("<html><body>"+chatStrings.join("<br>")+"</body></html>");

    afterContentAdd();
}


void HWChatWidget::nickAdded(const QString & nick, bool notifyNick)
{
    QSortFilterProxyModel * playersSortFilterModel = qobject_cast<QSortFilterProxyModel *>(chatNicks->model());
    if(!playersSortFilterModel)
        return;

    PlayersListModel * players = qobject_cast<PlayersListModel *>(playersSortFilterModel->sourceModel());

    if(!players)
        return;

    bool isIgnored = players->isFlagSet(nick, PlayersListModel::Ignore);

    if (isIgnored && m_isAdmin && m_autoKickEnabled)
    {
        emit kick(nick);
        return;
    }

    if ((!isIgnored) && (nick != m_userNick)) // don't auto-complete own name
        chatEditLine->addNickname(nick);

    emit nickCountUpdate(chatNicks->model()->rowCount());

    if (!isIgnored)
        printChatString(nick, QString("*** ") + tr("%1 has joined").arg(linkedNick(nick)), "Join", false);

    if (notifyNick && notify && (m_helloSounds.size() > 0))
    {
        SDLInteraction::instance().playSoundFile(
                            m_helloSounds.at(rand() % m_helloSounds.size()));
    }
}

void HWChatWidget::nickRemoved(const QString& nick)
{
    nickRemoved(nick, "");
}

void HWChatWidget::nickRemoved(const QString& nick, const QString & message)
{
    chatEditLine->removeNickname(nick);

    emit nickCountUpdate(chatNicks->model()->rowCount());

    if (message.isEmpty())
        printChatString(nick, QString("*** ") + tr("%1 has left").arg(linkedNick(nick)), "Leave", false);
    else
        printChatString(nick, QString("*** ") + tr("%1 has left (%2)").arg(linkedNick(nick)).arg(messageToHTML(message)), "Leave", false);
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

    if (!m_userNick.isEmpty())
        m_highlights.append(QRegExp(hlRegExp.arg(QRegExp::escape(m_userNick.toLower()))));

    QFile file(cfgdir->absolutePath() + "/" + m_userNick.toLower() + "_highlight.txt");

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

    QFile file2(cfgdir->absolutePath() + "/" + m_userNick.toLower() + "_hlregexp.txt");

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

void HWChatWidget::onPlayerInfo(
            const QString & nick,
            const QString & ip,
            const QString & version,
            const QString & roomInfo)
{
    addLine("msg_PlayerInfo", QString(" >>> %1 - <span class=\"ipaddress\">%2</span> <span class=\"version\">%3</span> <span class=\"location\">%4</span>")
        .arg(linkedNick(nick))
        .arg(Qt::escape(ip == "[]"?"":ip))
        .arg(Qt::escape(version))
        .arg(Qt::escape(roomInfo))
    );
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
        chatNicks->scrollTo(chatNicks->selectionModel()->selectedRows()[0]);
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
        chatNicks->scrollTo(chatNicks->selectionModel()->selectedRows()[0]);
}

void HWChatWidget::chatNickDoubleClicked(const QModelIndex &index)
{
    m_clickedNick = index.data().toString();

    QList<QAction *> actions = chatNicks->actions();
    actions.first()->activate(QAction::Trigger);
}


void HWChatWidget::adminAccess(bool b)
{
    chatNicks->removeAction(acKick);
    //chatNicks->removeAction(acBan);

    m_isAdmin = b;

    if(b)
    {
        chatNicks->insertAction(0, acKick);
        //chatNicks->insertAction(0, acBan);
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
    QString dest = "physfs://css/chat.css";

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
            emit consoleCommand(tline.mid(1));

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

    QSortFilterProxyModel * sfpModel = qobject_cast<QSortFilterProxyModel *>(model);
    if (sfpModel)
        m_usersModel = qobject_cast<PlayersListModel*>(sfpModel->sourceModel());
    else
        m_usersModel = qobject_cast<PlayersListModel*>(model);
}

void HWChatWidget::nicksContextMenuRequested(const QPoint &pos)
{
    QModelIndexList mil = chatNicks->selectionModel()->selectedRows();

    QString nick;

    if(mil.size())
        nick = mil[0].data().toString();
    else
        nick = m_clickedNick;

    bool isOnline = (mil.size() > 0);

    QSortFilterProxyModel * playersSortFilterModel = qobject_cast<QSortFilterProxyModel *>(chatNicks->model());
    if(!playersSortFilterModel)
        return;

    PlayersListModel * players = qobject_cast<PlayersListModel *>(playersSortFilterModel->sourceModel());

    if(!players)
        return;

    bool isSelf = (nick == m_userNick);
    bool isInRoom = players->isFlagSet(nick, PlayersListModel::InRoom);

    acFollow->setVisible(!isSelf && isInRoom);

    acInfo->setVisible(isOnline);

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
        acKick->setVisible(!isSelf && isOnline);
        acBan->setVisible(!isSelf);
    }

    m_nicksMenu->clear();

    foreach(QAction * action, chatNicks->actions())
        m_nicksMenu->addAction(action);

    m_nicksMenu->popup(chatNicks->mapToGlobal(pos));
}

void HWChatWidget::beforeContentAdd()
{
    m_scrollBarPos = chatText->verticalScrollBar()->value();
    m_scrollToBottom = m_scrollBarPos == chatText->verticalScrollBar()->maximum();
}

void HWChatWidget::afterContentAdd()
{
    if(m_scrollToBottom)
    {
        chatText->verticalScrollBar()->setValue(chatText->verticalScrollBar()->maximum());
        chatText->moveCursor(QTextCursor::End);
    } else
    {
        chatText->verticalScrollBar()->setValue(m_scrollBarPos);
    }
}

void HWChatWidget::resizeEvent(QResizeEvent * event)
{
    Q_UNUSED(event);

    afterContentAdd();
}

void HWChatWidget::showEvent(QShowEvent * event)
{
    Q_UNUSED(event);

     afterContentAdd();
}
