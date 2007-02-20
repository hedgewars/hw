#include <QListWidget>
#include <QLineEdit>

#include "chatwidget.h"

HWChatWidget::HWChatWidget(QWidget* parent) :
  QWidget(parent),
  mainLayout(this)
{
  mainLayout.setSpacing(1);
  mainLayout.setMargin(1);

  chatEditLine = new QLineEdit(this);
  connect(chatEditLine, SIGNAL(returnPressed()), this, SLOT(returnPressed()));

  mainLayout.addWidget(chatEditLine, 1, 0);
  
  chatText = new QListWidget(this);
  chatText->setMinimumHeight(10);
  mainLayout.addWidget(chatText, 0, 0);
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
