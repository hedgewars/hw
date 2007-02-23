/*
 * Hedgewars, a worms-like game
 * Copyright (c) 2007 Igor Ulyanov <iulyanov@gmail.com>
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

#ifndef _CHAT_WIDGET_INCLUDED
#define _CHAT_WIDGET_INCLUDED

#include <QWidget>
#include <QString>
#include <QGridLayout>

class QListWidget;
class QLineEdit;

class HWChatWidget : public QWidget
{
  Q_OBJECT

 public:
  HWChatWidget(QWidget* parent=0);

 public slots:
  void onChatStringFromNet(const QStringList& str);
  void nickAdded(const QString& nick);
  void nickRemoved(const QString& nick);
  void clear();

 signals:
  void chatLine(const QString& str);

 private:
  QGridLayout mainLayout;
  QListWidget* chatText;
  QListWidget* chatNicks;
  QLineEdit* chatEditLine;

 private slots:
  void returnPressed();
};

#endif // _CHAT_WIDGET_INCLUDED
