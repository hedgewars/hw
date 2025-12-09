#ifndef BANDIALOG_H
#define BANDIALOG_H

#include <QDialog>

class QComboBox;
class QRadioButton;
class QLineEdit;

class BanDialog : public QDialog
{
    Q_OBJECT
public:
    explicit BanDialog(QWidget *parent = 0);

    bool byIP();
    int duration();
    QString banId();
    QString reason();

private:
    QRadioButton * rbIP;
    QRadioButton * rbNick;
    QLineEdit * leId;
    QLineEdit * leReason;
    QComboBox * cbTime;

private Q_SLOTS:
    void okClicked();
};

#endif // BANDIALOG_H
