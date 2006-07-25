#include <QLabel>
#include <QPixmap>
#include <QPushButton>
#include <QFrame>

#include <vertScrollArea.h>
#include "teamselect.h"
#include "teamselhelper.h"
#include "frameTeam.h"

void TeamSelWidget::addTeam(tmprop team)
{
  frameDontPlaying->addTeam(team);
  curDontPlayingTeams.push_back(team);
  QObject::connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(tmprop)),
		   this, SLOT(changeTeamStatus(tmprop)));
}

void TeamSelWidget::removeTeam(tmprop team)
{
  //curDontPlayingTeams.erase(std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team));
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

  FrameTeams* pRemoveTeams;
  FrameTeams* pAddTeams;
  if(itDontPlay==curDontPlayingTeams.end()) {
    pRemoveTeams=framePlaying;
    pAddTeams=frameDontPlaying;
  } else {
    pRemoveTeams=frameDontPlaying;
    pAddTeams=framePlaying;
  }

  pAddTeams->addTeam(team);
  pRemoveTeams->removeTeam(team);
}

void TeamSelWidget::addScrArea(FrameTeams* pfteams, QColor color)
{
  VertScrArea* area=new VertScrArea(color);
  area->setWidget(pfteams);
  mainLayout.addWidget(area, 30);
}

TeamSelWidget::TeamSelWidget(QWidget* parent) :
  QWidget(parent), mainLayout(this)
{
  framePlaying=new FrameTeams();
  frameDontPlaying=new FrameTeams();
  addScrArea(framePlaying, QColor("DarkTurquoise"));
  addScrArea(frameDontPlaying, QColor("LightGoldenrodYellow"));
}
