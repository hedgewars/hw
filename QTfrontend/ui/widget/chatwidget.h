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
        HWChatWidget(QWidget* parent, QSettings * gameSettings, bool notify);
        void setIgnoreListKick(bool enabled); ///< automatically kick people on ignore list (if possible)
        void setShowFollow(bool enabled);
        static const QString & styleSheet();
        void displayError(const QString & message);
        void displayNotice(const QString & message);
        void displayWarning(const QString & message);
        void setUser(const QString & nickname);
        void setUsersModel(QAbstractItemModel * model);

    protected:
        virtual void dragEnterEvent(QDragEnterEvent * event);
        virtual void dropEvent(QDropEvent * event);

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

    public slots:
        void onChatString(const QString& str);
        void onChatString(const QString& nick, const QString& str);
        void onServerMessage(const QString& str);
        void nickAdded(const QString& nick, bool notifyNick);
        void nickRemoved(const QString& nick);
        void clear();
        void adminAccess(bool);

    signals:
        void chatLine(const QString& str);
        void kick(const QString & str);
        void ban(const QString & str);
        void info(const QString & str);
        void follow(const QString &);
        void nickCountUpdate(int cnt);

    private:
        bool m_isAdmin;
        QGridLayout mainLayout;
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
