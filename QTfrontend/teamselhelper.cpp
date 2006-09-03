#include "teamselhelper.h"
#include "hwconsts.h"

#include <QPixmap>
#include <QPushButton>
#include <QPainter>

#include "hedgehogerWidget.h"

void TeamLabel::teamButtonClicked()
{
  emit teamActivated(text());
}

TeamShowWidget::TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent) :
  QWidget(parent), mainLayout(this), m_team(team), m_isPlaying(isPlaying)
{
  mainLayout.setSpacing(1);
  mainLayout.setMargin(2);
  this->setMaximumHeight(35);
  QPixmap* px=new QPixmap(QPixmap(datadir->absolutePath() + "/Forts/" + m_team.Fort + "L.png").scaled(40, 40));

  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Button, palette().color(backgroundRole()));

  QPushButton* butt=new QPushButton(*px, "", this);
  butt->setFlat(true);
  butt->setGeometry(0, 0, 30, 30);
  butt->setMaximumWidth(30);
  butt->setPalette(newPalette);
  mainLayout.addWidget(butt);
  butt->setIconSize(butt->size());

  QPushButton* bText=new QPushButton(team.TeamName, this);
  bText->setPalette(newPalette);
  bText->setFlat(true);
  mainLayout.addWidget(bText);

  if(m_isPlaying) {
    CHedgehogerWidget* phhoger=new CHedgehogerWidget(this);
    mainLayout.addWidget(phhoger);
  }

  QObject::connect(butt, SIGNAL(clicked()), this, SLOT(activateTeam()));
  QObject::connect(bText, SIGNAL(clicked()), this, SLOT(activateTeam()));
}

void TeamShowWidget::activateTeam()
{
  emit teamStatusChanged(m_team);
}
