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

class AbstractPage : public QWidget
{
    Q_OBJECT

 public:

 protected:
  AbstractPage(QWidget* parent = 0) {
    Q_UNUSED(parent);

    font14 = new QFont("MS Shell Dlg", 14);
    //setFocusPolicy(Qt::StrongFocus);
  }
  virtual ~AbstractPage() {};

  QPushButton* addButton(QString btname, QGridLayout* grid, int wy, int wx, bool iconed = false) {
    QPushButton* butt = new QPushButton(this);
    if (!iconed) {
      butt->setFont(*font14);
      butt->setText(btname);
      //butt->setStyleSheet("background-color: #0d0544");
    } else {
      const QIcon& lp=QIcon(btname);
      QSize sz = lp.actualSize(QSize(65535, 65535));
      butt->setIcon(lp);
      butt->setFixedSize(sz);
      butt->setIconSize(sz);
      butt->setFlat(true);
      butt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    }
    grid->addWidget(butt, wy, wx);
    return butt;
  };

  QPushButton* addButton(QString btname, QGridLayout* grid, int wy, int wx, int rowSpan, int columnSpan, bool iconed = false) {
    QPushButton* butt = new QPushButton(this);
    if (!iconed) {
      butt->setFont(*font14);
      butt->setText(btname);
    } else {
      const QIcon& lp=QIcon(btname);
      QSize sz = lp.actualSize(QSize(65535, 65535));
      butt->setIcon(lp);
      butt->setFixedSize(sz);
      butt->setIconSize(sz);
      butt->setFlat(true);
      butt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    }
    grid->addWidget(butt, wy, wx, rowSpan, columnSpan);
    return butt;
  };

  QPushButton* addButton(QString btname, QBoxLayout* box, int where, bool iconed = false) {
    QPushButton* butt = new QPushButton(this);
    if (!iconed) {
      butt->setFont(*font14);
      butt->setText(btname);
    } else {
      const QIcon& lp=QIcon(btname);
      QSize sz = lp.actualSize(QSize(65535, 65535));
      butt->setIcon(lp);
      butt->setFixedSize(sz);
      butt->setIconSize(sz);
      butt->setFlat(true);
      butt->setSizePolicy(QSizePolicy::Fixed, QSizePolicy::Fixed);
    }
    box->addWidget(butt, where);
    return butt;
  };

  QFont * font14;
};

#endif

