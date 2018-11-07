#ifndef GAMECONFIG_H
#define GAMECONFIG_H

#include <QList>
#include <QVector>

#include "team.h"

class GameConfig {
 public:
  explicit GameConfig();

  const char** argv() const;
  int argc() const;
  const QList<QByteArray> config() const;

  void clear();
  void cmdSeed(const QByteArray& seed);
  void cmdTheme(const QByteArray& theme);
  void cmdMapgen(int mapgen);
  void cmdTeam(const Team& team);

  bool isPreview() const;
  void setPreview(bool isPreview);

 private:
  mutable QVector<const char*> m_argv;
  QList<QByteArray> m_arguments;
  QList<QByteArray> m_cfg;
  QList<Team> m_teams;
  bool m_isPreview;

  void cfgAppend(const QByteArray& cmd);
};

#endif  // GAMECONFIG_H
