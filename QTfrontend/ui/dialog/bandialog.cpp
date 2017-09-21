#include <QFormLayout>
#include <QComboBox>
#include <QRadioButton>
#include <QLineEdit>
#include <QLabel>
#include <QPushButton>
#include <QHBoxLayout>
#include <QMessageBox>
#include "HWApplication.h"

#include "bandialog.h"

BanDialog::BanDialog(QWidget *parent) :
    QDialog(parent)
{
    QFormLayout * formLayout = new QFormLayout(this);

    rbIP = new QRadioButton(this);
    rbIP->setChecked(true);
    rbNick = new QRadioButton(this);
    leId = new QLineEdit(this);
    leReason = new QLineEdit(this);
    cbTime = new QComboBox(this);

    const int min = 60;
    const int hour = 60 * min;
    const int day = 24 * hour;
    cbTime->addItem(HWApplication::tr("%1 minutes", 0, 10).arg(10), 10 * min);
    cbTime->addItem(HWApplication::tr("%1 minutes", 0, 30).arg(30), 30 * min);
    cbTime->addItem(HWApplication::tr("%1 hour", 0, 1).arg(1), 1 * hour);
    cbTime->addItem(HWApplication::tr("%1 hours", 0, 3).arg(3), 3 * hour);
    cbTime->addItem(HWApplication::tr("%1 hours", 0, 5).arg(5), 5 * hour);
    cbTime->addItem(HWApplication::tr("%1 hours", 0, 12).arg(12), 12 * hour);
    cbTime->addItem(HWApplication::tr("%1 day", 0, 1).arg(1), 1 * day);
    cbTime->addItem(HWApplication::tr("%1 days", 0, 3).arg(3), 3 * day);
    cbTime->addItem(HWApplication::tr("%1 days", 0, 7).arg(7), 7 * day);
    cbTime->addItem(HWApplication::tr("%1 days", 0, 14).arg(14), 14 * day);
    cbTime->addItem(tr("permanent"), 3650 * 24 * 60 * 60);
    cbTime->setCurrentIndex(0);

    formLayout->addRow(tr("IP"), rbIP);
    formLayout->addRow(tr("Nick"), rbNick);
    formLayout->addRow(tr("IP/Nick"), leId);
    formLayout->addRow(tr("Reason"), leReason);
    formLayout->addRow(tr("Duration"), cbTime);

    formLayout->setLabelAlignment(Qt::AlignRight);

    QHBoxLayout * hbox = new QHBoxLayout();
    formLayout->addRow(hbox);
    QPushButton * btnOk = new QPushButton(tr("Ok"), this);
    QPushButton * btnCancel = new QPushButton(tr("Cancel"), this);
    hbox->addStretch();
    hbox->addWidget(btnOk);
    hbox->addWidget(btnCancel);

    connect(btnOk, SIGNAL(clicked()), this, SLOT(okClicked()));
    connect(btnCancel, SIGNAL(clicked()), this, SLOT(reject()));

    this->setWindowModality(Qt::WindowModal);
    this->setWindowTitle(tr("Ban player"));
}

bool BanDialog::byIP()
{
    return rbIP->isChecked();
}

int BanDialog::duration()
{
    return cbTime->itemData(cbTime->currentIndex()).toInt();
}

QString BanDialog::banId()
{
    return leId->text();
}

QString BanDialog::reason()
{
    return leReason->text().isEmpty() ? tr("you know why") : leReason->text();
}

void BanDialog::okClicked()
{
    if(leId->text().isEmpty())
    {
        QString warning_text;
        if (byIP())
            warning_text = QString(tr("Please specify an IP address."));
        else
            warning_text = QString(tr("Please specify a nickname."));

        QMessageBox::warning(this, tr("Warning"), warning_text);
        return;
    }

    accept();
}
