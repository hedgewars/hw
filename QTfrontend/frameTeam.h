#ifndef _FRAME_TEAM_INCLUDED
#define _FRAME_TEAM_INCLUDED

#include <QWidget>

#include "teamselect.h"
#include <map>

class FrameTeams : public QWidget
{
  Q_OBJECT

 friend class CHedgehogerWidget;

 public:
  FrameTeams(QWidget* parent=0);
  QWidget* getTeamWidget(HWTeam team);
  bool isFullTeams() const;

 public slots:
  void addTeam(HWTeam team, bool willPlay);
  void removeTeam(HWTeam team);

 private:
  const int maxHedgehogsPerGame;
  int overallHedgehogs;
  QVBoxLayout mainLayout;
  typedef map<HWTeam, QWidget*> tmapTeamToWidget;
  tmapTeamToWidget teamToWidget;
};

#endif // _FRAME_TAM_INCLUDED
