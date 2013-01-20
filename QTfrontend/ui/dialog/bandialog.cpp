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

    cbTime->addItem(HWApplication::tr("%1 minutes").arg("10"), 5 * 60);
    cbTime->addItem(HWApplication::tr("%1 minutes").arg("30"), 10 * 60);
    cbTime->addItem(HWApplication::tr("%1 hour").arg("10"), 60 * 60);
    cbTime->addItem(HWApplication::tr("%1 hours").arg("3"), 3 * 60 * 60);
    cbTime->addItem(HWApplication::tr("%1 hours").arg("5"), 5 * 60 * 60);
    cbTime->addItem(HWApplication::tr("%1 hours").arg("12"), 12 * 60 * 60);
    cbTime->addItem(HWApplication::tr("%1 day").arg("1"), 24 * 60 * 60);
    cbTime->addItem(HWApplication::tr("%1 days").arg("3"), 72 * 60 * 60);
    cbTime->addItem(HWApplication::tr("%1 days").arg("7"), 168 * 60 * 60);
    cbTime->addItem(HWApplication::tr("%1 days").arg("14"), 336 * 60 * 60);
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
        QMessageBox::warning(this, tr("Warning"), tr("Please, specify %1").arg(byIP() ? tr("IP") : tr("nickname")));
        return;
    }

    accept();
}
