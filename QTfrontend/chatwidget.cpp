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
  QListWidget* w=chatText;
  w->addItem(str[0]+": "+str[1]);
  w->scrollToBottom();
  w->setSelectionMode(QAbstractItemView::NoSelection);
}
