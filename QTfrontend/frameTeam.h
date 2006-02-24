#ifndef _FRAME_TEAM_INCLUDED
#define _FRAME_TEAM_INCLUDED

#include <QWidget>

#include "teamselect.h"
#include <map>

class FrameTeams : public QWidget
{
  Q_OBJECT

 public:
  FrameTeams(QWidget* parent=0);
  QWidget* getTeamWidget(tmprop team);

 public slots:
  void addTeam(tmprop team);
  void removeTeam(tmprop team);

 private:
  QVBoxLayout mainLayout;
  typedef map<tmprop, QWidget*> tmapTeamToWidget;
  tmapTeamToWidget teamToWidget;
};

#endif // _FRAME_TAM_INCLUDED
