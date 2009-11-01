#include "teamedit.h"
#include "ui_teamedit.h"

TeamEdit::TeamEdit(QWidget *parent) :
    QWidget(parent),
    m_ui(new Ui::TeamEdit)
{
    m_ui->setupUi(this);

    reset();
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

void TeamEdit::reset()
{
   QLayout * l = m_ui->scrollArea->widget()->layout();

   for(int i = 0; i < 8; ++i)
       l->itemAt(i)->widget()->setVisible(false);
}

void TeamEdit::setTeam(const QString & teamName, quint32 color)
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

void TeamEdit::addHedgehog(quint32 level, quint32 health, const QString & name)
{
   QLayout * l = m_ui->scrollArea->widget()->layout();

   int i = 0;
   while((i < 8) && (l->itemAt(i)->widget()->isVisible())) ++i;

   if(i < 8)
   {
       HedgehogEdit * he = qobject_cast<HedgehogEdit *>(l->itemAt(i)->widget());
       he->setHedgehog(level, health, name);
       l->itemAt(i)->widget()->setVisible(true);
   }
}

void TeamEdit::setLastHHHat(const QString & name)
{
   QLayout * l = m_ui->scrollArea->widget()->layout();

   int i = 0;
   while((i < 8) && (l->itemAt(i)->widget()->isVisible())) ++i;

   --i;

   HedgehogEdit * he = qobject_cast<HedgehogEdit *>(l->itemAt(i)->widget());
   he->setHat(name);
}

void TeamEdit::setLastHHCoords(int x, int y)
{
   QLayout * l = m_ui->scrollArea->widget()->layout();

   int i = 0;
   while((i < 8) && (l->itemAt(i)->widget()->isVisible())) ++i;

   --i;

   HedgehogEdit * he = qobject_cast<HedgehogEdit *>(l->itemAt(i)->widget());
   he->setCoordinates(x ,y);
}

