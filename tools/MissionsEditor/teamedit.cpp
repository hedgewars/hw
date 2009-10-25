#include "teamedit.h"
#include "ui_teamedit.h"

TeamEdit::TeamEdit(QWidget *parent) :
    QWidget(parent),
    m_ui(new Ui::TeamEdit)
{
    m_ui->setupUi(this);
}

TeamEdit::~TeamEdit()
{
    delete m_ui;
}

void TeamEdit::changeEvent(QEvent *e)
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
