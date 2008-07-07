/*
 * Hedgewars, a free turn based strategy game
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

#include <QListWidget>
#include <QLineEdit>

#include "chatwidget.h"

HWChatWidget::HWChatWidget(QWidget* parent) :
  QWidget(parent),
  mainLayout(this)
{
  mainLayout.setSpacing(1);
  mainLayout.setMargin(1);
  mainLayout.setSizeConstraint(QLayout::SetMinimumSize);
  mainLayout.setColumnStretch(0, 75);
  mainLayout.setColumnStretch(1, 25);

  chatEditLine = new QLineEdit(this);
  connect(chatEditLine, SIGNAL(returnPressed()), this, SLOT(returnPressed()));

  mainLayout.addWidget(chatEditLine, 1, 0, 1, 2);

  chatText = new QListWidget(this);
  chatText->setMinimumHeight(10);
  chatText->setMinimumWidth(10);
  chatText->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mainLayout.addWidget(chatText, 0, 0);

  chatNicks = new QListWidget(this);
  chatNicks->setMinimumHeight(10);
  chatNicks->setMinimumWidth(10);
  chatNicks->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
  mainLayout.addWidget(chatNicks, 0, 1);
}

void HWChatWidget::returnPressed()
{
  emit chatLine(chatEditLine->text());
  chatEditLine->clear();
}

void HWChatWidget::onChatStringFromNet(const QStringList& str)
{
  if (str.size() < 2) return;
  QListWidget* w=chatText;
  w->addItem(str[0]+": "+str[1]);
  w->scrollToBottom();
  w->setSelectionMode(QAbstractItemView::NoSelection);
}

void HWChatWidget::nickAdded(const QString& nick)
{
  chatNicks->addItem(nick);
}

void HWChatWidget::nickRemoved(const QString& nick)
{
  QList<QListWidgetItem *> items=chatNicks->findItems(nick, Qt::MatchExactly);
  for(QList<QListWidgetItem *>::iterator it=items.begin(); it!=items.end();) {
    chatNicks->takeItem(chatNicks->row(*it));
    ++it;
  }
}

void HWChatWidget::clear()
{
  chatNicks->clear();
}
