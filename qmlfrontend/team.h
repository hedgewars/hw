#ifndef TEAM_H
#define TEAM_H

#include <QObject>
#include <QVector>

struct Hedgehog {
  Hedgehog();

  QByteArray name;
  QByteArray hat;
  quint32 hp;
  int level;
};

class Team {
 public:
  explicit Team();

  void resize(int number);
  QVector<Hedgehog> hedgehogs() const;

  QByteArray name;
  QByteArray color;

 private:
  QVector<Hedgehog> m_hedgehogs;
  int m_hedgehogsNumber;
};

#endif  // TEAM_H
