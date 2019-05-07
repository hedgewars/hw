/*
 * Hedgewars, a free turn based strategy game
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

#ifndef _KEY_BINDER_H
#define _KEY_BINDER_H

#include <QWidget>
#include <QHash>

#include "binds.h"

class QListWidget;
class QTableWidgetItem;
class QTableWidget;
class QBoxLayout;
class QComboBox;
class QLabel;

// USAGE NOTE: Every time the widget comes into view, you must call resetInterface()

class KeyBinder : public QWidget
{
    Q_OBJECT

    public:
        KeyBinder(QWidget * parent = NULL, const QString & helpText = QString(), const QString & defaultText = QString(), const QString & resetButtonText = QString());
        ~KeyBinder();

        void setBindIndex(int keyIndex, int bindIndex);
        int bindIndex(int keyIndex);
        void resetInterface();
        bool hasConflicts();
        bool checkConflicts();
        bool checkConflictsWith(int bind, bool updateState);

    private:
        QHash<QObject *, QTableWidgetItem *> * bindComboBoxCellMappings;
        QHash<QTableWidgetItem *, QComboBox *> * bindCellComboBoxMappings;
        QTableWidget * selectedBindTable;
        QListWidget * catList;
        QBoxLayout *bindingsPages;
        QComboBox * CBBind[BINDS_NUMBER];
        QLabel * conflictLabel;
        QIcon * dropDownIcon;
        QIcon * conflictIcon;
        QString defaultText;
        bool enableSignal;
        bool p_hasConflicts;

    signals:
        void bindUpdate(int bindID);
        void resetAllBinds();

    private slots:
        void changeBindingsPage(int page);
        void bindChanged(const QString &);
        void bindCellClicked(QTableWidgetItem * item);
        void bindSelectionChanged();
};

#endif // _KEY_BINDER_H
