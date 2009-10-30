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

void TeamEdit::addTeam(const QString & teamName, quint32 color)
{
    m_ui->leTeamName->setText(teamName);
}

void TeamEdit::setFort(const QString & name)
{
    m_ui->leFort->setText(name);
}

void TeamEdit::setGrave(const QString & name)
{
    m_ui->leGrave->setText(name);
}

void TeamEdit::setVoicepack(const QString & name)
{
    m_ui->leVoicepack->setText(name);
}

