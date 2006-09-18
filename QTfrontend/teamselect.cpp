#include <QLabel>
#include <QPixmap>
#include <QPushButton>
#include <QFrame>
#include <QDebug>

#include <vertScrollArea.h>
#include "teamselect.h"
#include "teamselhelper.h"
#include "frameTeam.h"

void TeamSelWidget::addTeam(HWTeam team)
{
  frameDontPlaying->addTeam(team, false);
  curDontPlayingTeams.push_back(team);
  QObject::connect(frameDontPlaying->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		   this, SLOT(changeTeamStatus(HWTeam)));
}

//void TeamSelWidget::removeTeam(__attribute__ ((unused)) HWTeam team)
//{
  //curDontPlayingTeams.erase(std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team));
//}

void TeamSelWidget::changeTeamStatus(HWTeam team)
{
  list<HWTeam>::iterator itDontPlay=std::find(curDontPlayingTeams.begin(), curDontPlayingTeams.end(), team);
  list<HWTeam>::iterator itPlay=std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team);

  bool willBePlaying=itDontPlay!=curDontPlayingTeams.end();

  if(!willBePlaying) {
    // playing team => dont playing
    curDontPlayingTeams.push_back(*itPlay);
    curPlayingTeams.erase(itPlay);
  } else {
    // return if max playing teams reached
    if(framePlaying->isFullTeams()) return;
    // dont playing team => playing
    curPlayingTeams.push_back(*itDontPlay);
    curDontPlayingTeams.erase(itDontPlay);
  }

  FrameTeams* pRemoveTeams;
  FrameTeams* pAddTeams;
  if(!willBePlaying) {
    pRemoveTeams=framePlaying;
    pAddTeams=frameDontPlaying;
  } else {
    pRemoveTeams=frameDontPlaying;
    pAddTeams=framePlaying;
  }

  pAddTeams->addTeam(team, willBePlaying);
  pRemoveTeams->removeTeam(team);
  QObject::connect(pAddTeams->getTeamWidget(team), SIGNAL(teamStatusChanged(HWTeam)),
		   this, SLOT(changeTeamStatus(HWTeam)));

  QSize szh=pAddTeams->sizeHint();
  QSize szh1=pRemoveTeams->sizeHint();
  if(szh.isValid() && szh1.isValid()) {
    pAddTeams->resize(pAddTeams->size().width(), szh.height());
    pRemoveTeams->resize(pRemoveTeams->size().width(), szh1.height());
  }
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

void TeamSelWidget::resetPlayingTeams(const QStringList& teamslist)
{
  list<HWTeam>::iterator it;
  for(it=curPlayingTeams.begin(); it!=curPlayingTeams.end(); it++) {
    framePlaying->removeTeam(*it);
  }
  curPlayingTeams.clear();
  for(it=curDontPlayingTeams.begin(); it!=curDontPlayingTeams.end(); it++) {
    frameDontPlaying->removeTeam(*it);
  }
  curDontPlayingTeams.clear();

  for (QStringList::ConstIterator it = teamslist.begin(); it != teamslist.end(); ++it ) {
    addTeam(*it);
  }
}

bool TeamSelWidget::isPlaying(HWTeam team) const
{
  return std::find(curPlayingTeams.begin(), curPlayingTeams.end(), team)!=curPlayingTeams.end();
}

list<HWTeam> TeamSelWidget::getPlayingTeams() const
{
  return curPlayingTeams;
}

unsigned char TeamSelWidget::numHedgedogs(HWTeam team) const
{
  const TeamShowWidget* tsw=dynamic_cast<TeamShowWidget*>(framePlaying->getTeamWidget(team));
  if(!tsw) return 0;
  return tsw->getHedgehogsNum();
}
