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
