/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
 * Copyright (c) 2007-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef HEDGEWARS_SMARTLINEDIT
#define HEDGEWARS_SMARTLINEDIT

#include <QLineEdit>
#include <QStringList>
#include <QString>

#include <QEvent>
#include <QKeyEvent>

#include <QMutex>
#include <QRegExp>

class QLineEdit;

/**
 * A modification of QLineEdit that features:
 * + Auto-completion for word under cursor when the TAB key is pressed.
 * + ESC key clears text.
 * + History of previous contents, re-selectable using the arrow keys.
 *
 * Note:
 *   * A Keyword can either be a command (if first word) or
 *     a nickname (completed regardless of position in text).
 *   * Public methods for accessing keywords and history are thread-safe.
 * @author sheepluva
 * @since 0.9.17
 */
class SmartLineEdit : public QLineEdit
{
 Q_OBJECT

public:
    /**
    * Class constructor.
    * @param parent parent QWidget.
    * @param maxHistorySize maximum amount of history entries kept.
    */
    SmartLineEdit(QWidget * parent = 0, int maxHistorySize = 64);

    /**
     * Adds commands to the auto-completion feature.
     * @param commands list of commands to be added.
     */
    void addCommands(const QStringList & commands);

    /**
     * Adds a single nickname to the auto-completion feature.
     * @param nickname name to be added.
     */
    void addNickname(const QString & nickname);

    /**
     * Appends current text to history.
     */
    void rememberCurrentText();

    /**
     * Removes commands from the auto-completion feature.
     * @param commands list of commands to be removed.
     */
    void removeCommands(const QStringList & commands);

    /**
     * Removes a single nickname from the auto-completion feature.
     * @param nickname name to be removed.
     */
    void removeNickname(const QString & nickname);

    /**
     * Forget all keywords and input history.
     */
    void forgetEverything();


public slots:
    /**
     * Clears the contents.
     */
    void clear();


protected:
    /**
     * Overrides method of parent class.
     * Forward pressed TAB to parent class' method (for focus handling etc)
     * only if line is empty.
     * @param event the key event.
     * @return returns true if the event was recognized.
     */
    virtual bool event(QEvent * event);

    /**
     * Overrides method of parent class.
     * Autocompletes if TAB is reported as pressed key in the key event,
     * otherwise keys except for ESC and Up/Down (with no modifiers)
     * are forwarded to parent method.
     * ESC leads to the contents being cleared.
     * Arrow keys are used for navigating the history.
     * @param event the key event.
     */
    virtual void keyPressEvent(QKeyEvent * event);


private:
    QRegExp m_whitespace; // regexp that matches a whitespace

    int m_maxHistorySize; // the maximum allowed size for the history
    int m_curHistEntryIdx; // the index of the currently used entry or -1

    QStringList * m_cmds;  // list of recognized commands
    QStringList * m_nicks; // list of recognized nicknames

    QStringList * m_history; // history of previous inputs

    // these variables contain information about the last replacement
    // they get reset whenever cursor is moved or text is changed

    QString m_beforeMatch; // the string that was just matched
    bool m_hasJustMatched; // whether this widget just did an auto-completion
    QString m_prefix; // prefix of the text replacement this widget just did
    QString m_postfix; // postfix of the text replacement this widget just did

    QMutex m_keywordMutex; // make keyword QStringList action thread-safe
    QMutex m_historyMutex; // make history QStringList action thread-safe

    /**
     * Autocompletes the contents based on the known commands and/or names.
     */
    void autoComplete();

    /**
     * Navigates content history in the desired direction.
     * Note: no wrap-around on purpose (so that holding down/up will get the
     * the user to the respective end rather than into an endless cycle :P)
     * @param isGoingUp true: next older entry, false: next more recent entry.
     */
    void navigateHistory(bool isGoingUp);

    /**
     * Appends current text to history, without Mutex.
     */
    void rememberCurrentTextUnsynced();


private slots:
    /**
     * Resets the information about the last match and text replacement.
     */
    void resetAutoCompletionStatus();
};



#endif // HEDGEWARS_SMARTLINEDIT
