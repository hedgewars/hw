#include "teamselhelper.h"

#include <QPixmap>
#include <QPushButton>
#include "hwconsts.h"

void TeamLabel::teamButtonClicked()
{
  emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(HWTeam team, QWidget * parent) :
  QWidget(parent), mainLayout(this), m_team(team)
{
  this->setMaximumHeight(40);
  QPixmap* px=new QPixmap(QPixmap(datadir->absolutePath() + "/Forts/" + m_team.Fort + "L.png").scaled(40, 40));

  QPushButton* butt=new QPushButton(*px, "", this);
  butt->setFlat(true);
  butt->setGeometry(0, 0, 30, 30);
  butt->setMaximumWidth(30);
  mainLayout.addWidget(butt);
  butt->setIconSize(butt->size());

  QPushButton* bText=new QPushButton(team.TeamName, this);
  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Button, palette().color(backgroundRole()));
  bText->setPalette(newPalette);
  bText->setFlat(true);
  mainLayout.addWidget(bText);

  QObject::connect(butt, SIGNAL(clicked()), this, SLOT(activateTeam()));
  QObject::connect(bText, SIGNAL(clicked()), this, SLOT(activateTeam()));
}

void TeamShowWidget::activateTeam()
{
  emit teamStatusChanged(m_team);
}
