#ifndef PLAYERSLISTMODEL_H
#define PLAYERSLISTMODEL_H

#include <QStringListModel>

class PlayersListModel : public QStringListModel
{
    Q_OBJECT
public:
    explicit PlayersListModel(QObject *parent = 0);

signals:
    
public slots:
    void addPlayer(const QString & nickname);
    
};

#endif // PLAYERSLISTMODEL_H
