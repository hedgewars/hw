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
  dontPlayingLayout.addWidget(pTeamShowWidget);

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

  QGridLayout* pRemoveGrid = itDontPlay==curDontPlayingTeams.end() ? &playingLayout : &dontPlayingLayout;
  QGridLayout* pAddGrid = itDontPlay==curDontPlayingTeams.end() ? &dontPlayingLayout : &playingLayout;

  pRemoveGrid->removeWidget(teamToWidget[team]);
  pAddGrid->addWidget(teamToWidget[team]);
}

TeamSelWidget::TeamSelWidget(const vector<QString>& teams, QWidget* parent) :
  QWidget(parent), mainLayout(this)
{
  mainLayout.addLayout(&playingLayout);
  mainLayout.addLayout(&dontPlayingLayout);

  for(vector<QString>::const_iterator it=teams.begin(); it!=teams.end(); ++it) {
    addTeam(*it);
  }
}
