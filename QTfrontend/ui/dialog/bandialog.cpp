#include <QFormLayout>
#include <QComboBox>
#include <QRadioButton>
#include <QLineEdit>
#include <QLabel>
#include <QPushButton>
#include <QHBoxLayout>
#include <QMessageBox>

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

    cbTime->addItem(tr("10 minutes"), 5 * 60);
    cbTime->addItem(tr("30 minutes"), 10 * 60);
    cbTime->addItem(tr("1 hour"), 60 * 60);
    cbTime->addItem(tr("3 hours"), 3 * 60 * 60);
    cbTime->addItem(tr("5 hours"), 5 * 60 * 60);
    cbTime->addItem(tr("24 hours"), 24 * 60 * 60);
    cbTime->addItem(tr("3 days"), 72 * 60 * 60);
    cbTime->addItem(tr("7 days"), 168 * 60 * 60);
    cbTime->addItem(tr("14 days"), 336 * 60 * 60);
    cbTime->addItem(tr("permanent"), 3650 * 60 * 60);
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
