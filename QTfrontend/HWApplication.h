/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2012 Vittorio Giovara <vittorio.giovara@gmail.com>
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

#ifndef HWAPP_H
#define HWAPP_H

#include <QApplication>
#include "hwform.h"

class HWForm;
class QEvent;

/**
 * @brief Main class of the Qt application.
 *
 * By default uses :res/css/qt.css as style sheet for the main form.
 * See \repo{res/css/qt.css} for a more detailed description.
 *
 * @see http://doc.qt.nokia.com/4.5/stylesheet.html
 */
class HWApplication : public QApplication
{
        Q_OBJECT
    public:
        HWApplication(int &argc, char **argv);
        ~HWApplication() {};

        HWForm *form;
        QString *urlString;
        void fakeEvent();
    protected:
        bool event(QEvent *);
};

#endif

