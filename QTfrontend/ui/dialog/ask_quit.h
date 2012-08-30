/*
 * Hedgewars, a free turn based strategy game
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

#ifndef ASK_QUIT_H
#define ASK_QUIT_H

#include <QDialog>

class QLabel;
class HWForm;
class PageVideos;

class HWAskQuitDialog : public QDialog
{
        Q_OBJECT

    public:
        HWAskQuitDialog(QWidget* parent, HWForm *form);

    private slots:
        void goToPageVideos();
        void updateList();

    private:
        HWForm * form;
        QLabel * lbList;
};


#endif // INPUT_PASSWORD_H
