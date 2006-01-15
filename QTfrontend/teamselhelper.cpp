#include "teamselhelper.h"

#include <QPixmap>
#include <QPushButton>

void TeamLabel::teamButtonClicked()
{
  emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(tmprop team) :
  mainLayout(this), m_team(team)
{
  QLabel* pixlbl=new QLabel();
  pixlbl->setPixmap(QPixmap("./Data/Graphics/thinking.png"));
  mainLayout.addWidget(pixlbl);
  
  TeamLabel* lbl=new TeamLabel(team.teamName);
  mainLayout.addWidget(lbl);

  QPushButton* butt=new QPushButton("o");
  mainLayout.addWidget(butt);

  QObject::connect(butt, SIGNAL(clicked()), this, SLOT(activateTeam()));
}

void TeamShowWidget::activateTeam()
{
  emit teamStatusChanged(m_team);
}
