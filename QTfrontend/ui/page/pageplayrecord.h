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

#ifndef PLAYRECORDPAGE_H
#define PLAYRECORDPAGE_H

#include <QDir>

#include "AbstractPage.h"

class QPushButton;
class QListWidget;

class PagePlayDemo : public AbstractPage
{
        Q_OBJECT

    public:
        enum RecordType
        {
            RT_Demo,
            RT_Save
        };

        PagePlayDemo(QWidget* parent = 0);

        void FillFromDir(RecordType rectype);
        bool isSave();

        QPushButton *BtnPlayDemo;
        QPushButton *BtnRenameRecord;
        QPushButton *BtnRemoveRecord;
        QListWidget *DemosList;

    public slots:
        void refresh();

    private:
        QLayout * bodyLayoutDefinition();
        void connectSignals();

        RecordType recType;

    private slots:
        void renameRecord();
        void removeRecord();
};


#endif // PLAYRECORDPAGE_H
