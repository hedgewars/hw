#include "hedgehogedit.h"
#include "ui_hedgehogedit.h"

HedgehogEdit::HedgehogEdit(QWidget *parent) :
    QFrame(parent),
    m_ui(new Ui::HedgehogEdit)
{
    m_ui->setupUi(this);
}

HedgehogEdit::~HedgehogEdit()
{
    delete m_ui;
}

void HedgehogEdit::changeEvent(QEvent *e)
{
    QWidget::changeEvent(e);
    switch (e->type()) {
    case QEvent::LanguageChange:
        m_ui->retranslateUi(this);
        break;
    default:
        break;
    }
}

void HedgehogEdit::setHedgehog(quint32 level, quint32 health, const QString & name)
{
    m_ui->cbLevel->setCurrentIndex(level);
    m_ui->sbHealth->setValue(health);
    m_ui->leName->setText(name);
}

void HedgehogEdit::setHat(const QString & name)
{
    m_ui->leHat->setText(name);
}

void HedgehogEdit::setCoordinates(int x, int y)
{
    m_ui->pbCoordinates->setText(QString("%1x%2").arg(x).arg(y));
}
