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

#ifndef HATPROMPT_H
#define HATPROMPT_H

#include <QWidget>
#include <QDialog>
#include <QListView>

class QLineEdit;
class QModelIndex;
class QSortFilterProxyModel;
class LineEditCursor;

class HatListView : public QListView
{
    friend class HatPrompt;

    public:
        HatListView(QWidget* parent = 0) : QListView(parent){}
        void moveUp();
        void moveDown();
        void moveLeft();
        void moveRight();
};

class HatPrompt : public QDialog
{
        Q_OBJECT

    public:
        HatPrompt(int currentIndex = 0, QWidget* parent = 0);

    private:
        LineEditCursor * txtFilter;
        HatListView * list;
        QSortFilterProxyModel * filterModel;

    private slots:
        void onAccepted();
        void hatChosen(const QModelIndex & index);
        void filterChanged(const QString & text);
        void moveUp();
        void moveDown();
        void moveLeft();
        void moveRight();
};

#endif // HATPROMPT_H
