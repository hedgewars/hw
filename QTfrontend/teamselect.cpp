#include <QLabel>
#include <QPixmap>
#include <QPushButton>

#include <algorithm>

#include "teamselect.h"
#include "teamselhelper.h"

void TeamSelWidget::addTeam(tmprop team)
{
  curDontPlayingTeams.push_back(team);
  TeamShowWidget* pTeamShowWidget =new TeamShowWidget(team);
  dontPlayingLayout->addWidget(pTeamShowWidget);

  teamToWidget.insert(make_pair(team, pTeamShowWidget));

  QObject::connect(pTeamShowWidget, SIGNAL(teamStatusChanged(tmprop)), this, SLOT(changeTeamStatus(tmprop)));
}

void TeamSelWidget::removeTeam(tmprop team)
{
  curDontPlayingTeams.erase(std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team));
}

void TeamSelWidget::changeTeamStatus(tmprop team)
{
  list<tmprop>::iterator itDontPlay=std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team);
  list<tmprop>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);

  if(itDontPlay==curDontPlayingTeams.end()) {
    // playing team => dont playing
    curDontPlayingTeams.push_back(*itPlay);
    curPlayingTeams.erase(itPlay);
  } else {
    // dont playing team => playing
    curPlayingTeams.push_back(*itDontPlay);
    curDontPlayingTeams.erase(itDontPlay);
  }

  QGridLayout* pRemoveGrid;
  QGridLayout* pAddGrid;
  QWidget* newParent;
  if(itDontPlay==curDontPlayingTeams.end()) {
    pRemoveGrid=playingLayout;
    pAddGrid=dontPlayingLayout;
    newParent=dontPlayingColorFrame;
  } else {
    pRemoveGrid=dontPlayingLayout;
    pAddGrid=playingLayout;
    newParent=playingColorFrame;
  }

  pRemoveGrid->removeWidget(teamToWidget[team]);
  teamToWidget[team]->setParent(newParent);
  pAddGrid->addWidget(teamToWidget[team]);
}

TeamSelWidget::TeamSelWidget(QWidget* parent) :
  QWidget(parent), mainLayout(this)
{
  playingColorFrame = new QFrame;
  QPalette newPalette = palette();
  newPalette.setColor(QPalette::Background, QColor("DarkTurquoise"));
  playingColorFrame->setPalette(newPalette);
  mainLayout.addWidget(playingColorFrame);

  dontPlayingColorFrame = new QFrame;
  newPalette.setColor(QPalette::Background, QColor("LightGoldenrodYellow")); //BlanchedAlmond MistyRose honeydew PeachPuff LightCoral
  dontPlayingColorFrame->setPalette(newPalette);
  mainLayout.addWidget(dontPlayingColorFrame);
  
  playingLayout = new QGridLayout(playingColorFrame);
  dontPlayingLayout = new QGridLayout(dontPlayingColorFrame);
}
