#include "playerslistmodel.h"

PlayersListModel::PlayersListModel(QObject *parent) :
    QStringListModel(parent)
{

}

void PlayersListModel::addPlayer(const QString & nickname)
{
    insertRows(rowCount(), 1);

    setData(index(rowCount() - 1), nickname);
}
