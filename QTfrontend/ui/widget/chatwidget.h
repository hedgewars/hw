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

#ifndef _CHAT_WIDGET_INCLUDED
#define _CHAT_WIDGET_INCLUDED

#include <QWidget>
#include <QString>
#include <QGridLayout>
#include <QList>
#include <QPair>
#include <QRegExp>
#include <QHash>
#include <QListWidgetItem>

#include "SDLInteraction.h"

#include "SmartLineEdit.h"
#include "playerslistmodel.h"

class QTextBrowser;
class QLineEdit;
class QListView;
class QSettings;
class QAbstractItemModel;
class QMenu;

/**
 * @brief Chat widget.
 *
 * By default uses :res/css/chat.css as style sheet for chat.
 * See \repo{res/css/chat.css} for a more detailed description.
 *
 * @see http://doc.qt.nokia.com/4.5/richtext-html-subset.html#css-properties
 */

class HWChatWidget : public QWidget
{
        Q_OBJECT

    public:
        HWChatWidget(QWidget* parent, bool notify);
        void setIgnoreListKick(bool enabled); ///< automatically kick people on ignore list (if possible)
        void setShowFollow(bool enabled);
        static const QString & styleSheet();
        void displayError(const QString & message);
        void displayNotice(const QString & message);
        void displayWarning(const QString & message);
        void setUser(const QString & nickname);
        void setUsersModel(QAbstractItemModel * model);
        void setSettings(QSettings * settings);

    protected:
        virtual void dragEnterEvent(QDragEnterEvent * event);
        virtual void dropEvent(QDropEvent * event);
        virtual void resizeEvent(QResizeEvent * event);
        virtual void showEvent(QShowEvent * event);

    private:
        static QString * s_styleSheet;
        static QStringList * s_displayNone;
        static bool s_isTimeStamped;
        static QString s_tsFormat;
        static const QRegExp URLREGEXP;

        static void setStyleSheet(const QString & styleSheet = "");

        void addLine(const QString & cssClass, QString line, bool isHighlight = false);
        bool parseCommand(const QString & line);
        void discardStyleSheet();
        void saveStyleSheet();
        QString linkedNick(const QString & nickname);
        void beforeContentAdd();
        void afterContentAdd();
        bool isInGame();

        /**
         * @brief Checks whether the message contains a highlight.
         * @param sender the sender of the message
         * @param message the message
         * @return true if the sender is somebody else and the message contains a highlight, otherwise false
         */
        bool containsHighlight(const QString & sender, const QString & message);
        /**
         * @brief Escapes HTML chars in the message and converts URls to HTML links.
         * @param message the message to be converted to HTML
         * @return the HTML message
         */
        QString messageToHTML(const QString & message);
        void printChatString(
            const QString & nick,
            const QString & str,
            const QString & cssClassPart,
            bool highlight);

    public slots:
        void onChatAction(const QString & nick, const QString & str);
        void onChatMessage(const QString & nick, const QString & str);
        void onServerMessage(const QString& str);
        void nickAdded(const QString& nick, bool notifyNick);
        void nickRemoved(const QString& nick);
        void nickRemoved(const QString& nick, const QString& message);
        void clear();
        void adminAccess(bool);
        void onPlayerInfo(
            const QString & nick,
            const QString & ip,
            const QString & version,
            const QString & roomInfo);

    signals:
        void chatLine(const QString& str);
        void kick(const QString & str);
        void ban(const QString & str);
        void info(const QString & str);
        void follow(const QString &);
        void nickCountUpdate(int cnt);
        void consoleCommand(const QString & command);

    private:
        PlayersListModel* m_usersModel;
        bool m_isAdmin;
        QHBoxLayout mainLayout;
        QTextBrowser* chatText;
        QStringList chatStrings;
        QListView* chatNicks;
        SmartLineEdit* chatEditLine;
        QAction * acInfo;
        QAction * acKick;
        QAction * acBan;
        QAction * acFollow;
        QAction * acIgnore;
        QAction * acFriend;
        QSettings * gameSettings;
        QMenu * m_nicksMenu;
        QStringList m_helloSounds;
        QString m_hilightSound;
        QString m_userNick;
        QString m_clickedNick;
        QList<QRegExp> m_highlights; ///< regular expressions used for highlighting
        bool notify;
        bool m_autoKickEnabled;
        bool m_scrollToBottom;
        int m_scrollBarPos;

    private slots:
        void returnPressed();
        void onBan();
        void onKick();
        void onInfo();
        void onFollow();
        void onIgnore();
        void onFriend();
        void chatNickDoubleClicked(const QModelIndex & index);
        void linkClicked(const QUrl & link);
        void nicksContextMenuRequested(const QPoint & pos);
};

#endif // _CHAT_WIDGET_INCLUDED
