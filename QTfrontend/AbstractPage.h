/*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

#ifndef ABSTRACTPAGE_H
#define ABSTRACTPAGE_H

#include <QWidget>
#include <QPushButton>
#include <QFont>
#include <QGridLayout>
#include <QComboBox>
#include <QSignalMapper>

class QPushButton;
class QGroupBox;
class QComboBox;
class QLabel;
class QToolBox;
class QLineEdit;
class QListWidget;
class QCheckBox;
class QSpinBox;
class QTextEdit;
class QRadioButton;
class QTableView;
class QTextBrowser;
class QTableWidget;
class QAction;
class QDataWidgetMapper;
class QAbstractItemModel;
class QSettings;
class QSlider;
class QGridlayout;

class AbstractPage : public QWidget
{
    Q_OBJECT

    signals:
        void goBack();

    protected:
        // constructor and virtual destructor
        AbstractPage(QWidget* parent = 0);
        virtual ~AbstractPage() {};

        QPushButton * addButton(const QString & btname, QGridLayout* grid, int wy, int wx, bool hasIcon = false);
        QPushButton * addButton(const QString & btname, QGridLayout* grid, int wy, int wx, int rowSpan, int columnSpan, bool hasIcon = false);
        QPushButton * addButton(const QString & btname, QBoxLayout* box, int where, bool hasIcon = false);

        QFont * font14;

    private:
        QPushButton * formattedButton(const QString & btname, bool hasIcon);
};

#endif

