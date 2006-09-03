#include "frameTeam.h"
#include "teamselhelper.h"

#include <QResizeEvent>
#include <QCoreApplication>

using namespace std;

FrameTeams::FrameTeams(QWidget* parent) :
  QWidget(parent), mainLayout(this)
{
}

void FrameTeams::addTeam(HWTeam team, bool willPlay)
{
  TeamShowWidget* pTeamShowWidget =new TeamShowWidget(team, willPlay, this);
//  int hght=teamToWidget.empty() ? 0 : teamToWidget.begin()->second->size().height();
  teamToWidget.insert(make_pair(team, pTeamShowWidget));
  mainLayout.addWidget(pTeamShowWidget);
  QResizeEvent* pevent=new QResizeEvent(parentWidget()->size(), parentWidget()->size());
  QCoreApplication::postEvent(parentWidget(), pevent);
}

void FrameTeams::removeTeam(HWTeam team)
{
  tmapTeamToWidget::iterator it=teamToWidget.find(team);
  mainLayout.removeWidget(it->second);
  delete it->second;
  teamToWidget.erase(team);
}

QWidget* FrameTeams::getTeamWidget(HWTeam team)
{
  tmapTeamToWidget::iterator it=teamToWidget.find(team);
  QWidget* ret = it!=teamToWidget.end() ? it->second : 0;
  if(!ret) throw; // FIXME: this is debug exception
  return ret;
}
