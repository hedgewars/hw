/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2007 Igor Ulyanov <iulyanov@gmail.com>
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

/**
 * @file
 * @brief SmartLineEdit class definition
 */

#ifndef HEDGEWARS_SMARTLINEEDIT_H
#define HEDGEWARS_SMARTLINEEDIT_H

#include <QMap>
#include <QString>
#include <QStringList>

#include <QEvent>
#include <QKeyEvent>

#include <QRegExp>

#include "HistoryLineEdit.h"

/**
 * @brief {@link HistoryLineEdit} that features auto-completion with TAB key
 *         and clear with ESC key.
 *
 * Notes:
 * <ul>
 *   <li>A Keyword can either be a command (if first word) or
 *       a nickname (completed regardless of position in text).</li>
 * </ul>
 *
 * @author sheepluva
 * @since 0.9.17
 */
class SmartLineEdit : public HistoryLineEdit
{
        Q_OBJECT

    public:
        /**
        * @brief Class constructor.
        * @param parent parent QWidget.
        * @param maxHistorySize maximum amount of history entries kept.
        */
        SmartLineEdit(QWidget * parent = 0, int maxHistorySize = 64);

        /**
        * @brief Class destructor.
        */
        ~SmartLineEdit();

        /**
         * @brief Adds commands to the auto-completion feature.
         * @param commands list of commands to be added.
         */
        void addCommands(const QStringList & commands);

        /**
         * @brief Adds a single nickname to the auto-completion feature.
         * @param nickname name to be added.
         */
        void addNickname(const QString & nickname);

        /**
         * @brief Removes commands from the auto-completion feature.
         * @param commands list of commands to be removed.
         */
        void removeCommands(const QStringList & commands);

        /**
         * @brief Removes a single nickname from the auto-completion feature.
         * @param nickname name to be removed.
         */
        void removeNickname(const QString & nickname);

        /**
         * @brief Forget all keywords and input history.
         */
        void reset();


    protected:
        /**
         * @brief Overrides method of parent class.
         * Forward pressed TAB to parent class' method (for focus handling etc)
         * only if line is empty.
         *
         * @param event the event.
         * @return returns true if the event was recognized.
         */
        virtual bool event(QEvent * event);

        /**
         * @brief Overrides method of parent class.
         * Autocompletes if TAB is reported as pressed key in the key event,
         * ESC leads to the contents being cleared.
         *
         * Other keys are forwarded to parent method.
         *
         * @param event the key event.
         */
        virtual void keyPressEvent(QKeyEvent * event);


    private:
        QRegExp m_whitespace; ///< regexp that matches a whitespace

        QStringList * m_cmds;  ///< list of recognized commands
        QStringList * m_nicks; ///< list of recognized nicknames

        /// recognized nicknames, sorted case-insensitive
        QMap<QString, QString> * m_sorted_nicks;

        // these variables contain information about the last replacement
        // they get reset whenever cursor is moved or text is changed

        QString m_beforeMatch; ///< the string that was just matched
        bool m_hasJustMatched; ///< whether this widget just did an auto-completion
        QString m_prefix; ///< prefix of the text replacement this widget just did
        QString m_postfix; ///< postfix of the text replacement this widget just did

        /**
         * @brief Autocompletes the contents based on the known commands and/or names.
         */
        void autoComplete();


    private slots:
        /**
         * @brief Resets the information about the last match and text replacement.
         */
        void resetAutoCompletionStatus();
};



#endif // HEDGEWARS_SMARTLINEEDIT_H
