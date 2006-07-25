#include "teamselhelper.h"

#include <QPixmap>
#include <QPushButton>

void TeamLabel::teamButtonClicked()
{
  emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(tmprop team, QWidget * parent) :
  QWidget(parent), mainLayout(this), m_team(team)
{
  this->setMaximumHeight(40);
  QLabel* pixlbl=new QLabel();
  pixlbl->setPixmap(QPixmap("./Data/Graphics/thinking.png"));
  mainLayout.addWidget(pixlbl);

  TeamLabel* lbl=new TeamLabel(team.teamName);
  mainLayout.addWidget(lbl);

  QPushButton* butt=new QPushButton("o");
  butt->setGeometry(0, 0, 25, 25);
  butt->setMaximumWidth(30);
  mainLayout.addWidget(butt);

  QObject::connect(butt, SIGNAL(clicked()), this, SLOT(activateTeam()));
}

void TeamShowWidget::activateTeam()
{
  emit teamStatusChanged(m_team);
}
