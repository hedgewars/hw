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
 TeamShowWidget(tmprop team);
 
 private:
 QHBoxLayout mainLayout;
 tmprop m_team;

 signals:
 void teamStatusChanged(tmprop team);
};

#endif // _TEAMSEL_HELPER_INCLUDED
