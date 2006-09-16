#ifndef _TEAMSEL_HELPER_INCLUDED
#define _TEAMSEL_HELPER_INCLUDED

#include <QLabel>
#include <QWidget>
#include <QString>

#include "teamselect.h"
#include "hedgehogerWidget.h"

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
 TeamShowWidget(HWTeam team, bool isPlaying, QWidget * parent);
 void setPlaying(bool isPlaying);
 unsigned char getHedgehogsNum();
 
 private:
 TeamShowWidget();
 QHBoxLayout mainLayout;
 HWTeam m_team;
 bool m_isPlaying;
 CHedgehogerWidget* phhoger;

 signals:
 void teamStatusChanged(HWTeam team);
};

#endif // _TEAMSEL_HELPER_INCLUDED
