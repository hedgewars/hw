#ifndef _TEAM_SELECT_INCLUDED
#define _TEAM_SELECT_INCLUDED

#include <QWidget>
#include <QVBoxLayout>
#include <QFrame>

#include <list>
#include <map>

using namespace std;

struct tmprop
{
  tmprop(QString nm) : teamName(nm){};
  QString teamName;
  QString pixmapFileName;
  bool operator==(const tmprop& t1) const {
    return teamName==t1.teamName;
  };
  bool operator<(const tmprop& t1) const {
    return teamName<t1.teamName;
  };
};

class TeamSelWidget : public QWidget
{
  Q_OBJECT
 
 public:
  TeamSelWidget(QWidget* parent=0);
  void addTeam(tmprop team);
  void removeTeam(tmprop team);

private slots:
  void changeTeamStatus(tmprop team);

 private:
  QVBoxLayout mainLayout;

  QFrame* playingColorFrame;
  QFrame* dontPlayingColorFrame;
  QGridLayout* playingLayout;
  QGridLayout* dontPlayingLayout;

  list<tmprop> curPlayingTeams;
  list<tmprop> curDontPlayingTeams;
  map<tmprop, QWidget*> teamToWidget;
};

#endif // _TEAM_SELECT_INCLUDED
