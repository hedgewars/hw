/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006, 2007 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef PLAYRECORDPAGE_H
#define PLAYRECORDPAGE_H

#include <QDir>

#include "pages.h"

class QPushButton;
class QListWidget;

class PagePlayDemo : public AbstractPage
{
    Q_OBJECT

public:
    enum RecordType {
        RT_Demo,
        RT_Save
    };

    PagePlayDemo(QWidget* parent = 0);

    void FillFromDir(RecordType rectype);

    QPushButton *BtnBack;
    QPushButton *BtnPlayDemo;
    QPushButton *BtnRenameRecord;
    QPushButton *BtnRemoveRecord;
    QListWidget *DemosList;

private:
    RecordType recType;

private slots:
    void renameRecord();
    void removeRecord();
};


#endif // PLAYRECORDPAGE_H
