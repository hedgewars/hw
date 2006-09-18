#ifndef _TEAM_SELECT_INCLUDED
#define _TEAM_SELECT_INCLUDED

#include <QWidget>
#include <QVBoxLayout>
class QFrame;

#include <list>
#include <map>

#include "team.h"

class TeamSelWidget;
class FrameTeams;

using namespace std;

class TeamSelWidget : public QWidget
{
  Q_OBJECT
 
 public:
  TeamSelWidget(QWidget* parent=0);
  void addTeam(HWTeam team);
  //void removeTeam(HWTeam team);
  void resetPlayingTeams(const QStringList& teamslist);
  bool isPlaying(HWTeam team) const;
  unsigned char numHedgedogs(HWTeam team) const;
  list<HWTeam> getPlayingTeams() const;

private slots:
  void changeTeamStatus(HWTeam team);

 private:
  void addScrArea(FrameTeams* pfteams, QColor color);
  FrameTeams* frameDontPlaying;
  FrameTeams* framePlaying;

  QVBoxLayout mainLayout;

  list<HWTeam> curPlayingTeams;
  list<HWTeam> curDontPlayingTeams;
};

#endif // _TEAM_SELECT_INCLUDED
