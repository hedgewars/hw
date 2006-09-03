#ifndef _TEAMSEL_HELPER_INCLUDED
#define _TEAMSEL_HELPER_INCLUDED

#include <QLabel>
#include <QWidget>
#include <QString>

#include "teamselect.h"

class TeamLabel : public QLabel
{
 Q_OBJECT

 public:
 TeamLabel(const QString& inp_str) : QLabel(inp_str) {};

 signals:
 void teamActivated(QString team_name);

 public slots:
 void teamButtonClicked();

};

class TeamShowWidget : public QWidget
{
 Q_OBJECT

 private slots:
 void activateTeam();

 public:
 TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent = 0);
 void setPlaying(bool isPlaying);
 
 private:
 QHBoxLayout mainLayout;
 HWTeam m_team;
 bool m_isPlaying;

 signals:
 void teamStatusChanged(HWTeam team);
};

#endif // _TEAMSEL_HELPER_INCLUDED
