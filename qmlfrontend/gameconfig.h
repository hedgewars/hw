#ifndef GAMECONFIG_H
#define GAMECONFIG_H

#include <QObject>

class GameConfig : public QObject
{
  Q_OBJECT
public:
  explicit GameConfig(QObject *parent = nullptr);

signals:

public slots:
};

#endif // GAMECONFIG_H