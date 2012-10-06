#include <QModelIndexList>
#include <QModelIndex>
#include <QPainter>

#include "playerslistmodel.h"

PlayersListModel::PlayersListModel(QObject *parent) :
    QAbstractListModel(parent)
{

}


int PlayersListModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    else
        return m_data.size();
}


QVariant PlayersListModel::data(const QModelIndex &index, int role) const
{
    if(!index.isValid())
        return QVariant(QVariant::Invalid);

    return m_data.at(index.row()).value(role);
}


bool PlayersListModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if(!index.isValid() || index.row() < 0 || index.row() >= rowCount() || index.column() != 0)
        return false;

    m_data[index.row()].insert(role, value);

    emit dataChanged(index, index);

    return true;
}


bool PlayersListModel::insertRow(int row, const QModelIndex &parent)
{
    return insertRows(row, 1, parent);
}


bool PlayersListModel::insertRows(int row, int count, const QModelIndex &parent)
{
    if(parent.isValid() || row > rowCount() || row < 0 || count < 1)
        return false;

    beginInsertRows(parent, row, row + count - 1);

    for(int i = 0; i < count; ++i)
        m_data.insert(row, DataEntry());

    endInsertRows();

    return true;
}


bool PlayersListModel::removeRows(int row, int count, const QModelIndex &parent)
{
    if(parent.isValid() || row + count > rowCount() || row < 0 || count < 1)
        return false;

    beginRemoveRows(parent, row, row + count - 1);

    for(int i = 0; i < count; ++i)
        m_data.removeAt(row);

    endRemoveRows();

    return true;
}


void PlayersListModel::addPlayer(const QString & nickname)
{
    insertRow(rowCount());

    setData(index(rowCount() - 1), nickname);

    updateIcon(index(rowCount() - 1));
}


void PlayersListModel::removePlayer(const QString & nickname)
{
    QModelIndexList mil = match(index(0, 0), Qt::DisplayRole, nickname);

    if(mil.size())
        removeRow(mil[0].row());
}


void PlayersListModel::setFlag(const QString &nickname, StateFlag flagType, bool isSet)
{
    QModelIndexList mil = match(index(0), Qt::DisplayRole, nickname);

    if(mil.size())
    {
        setData(mil[0], flagType, isSet);
        updateIcon(mil[0]);
    }
}


void PlayersListModel::updateIcon(const QModelIndex & index)
{
    quint32 iconNum = 0;

    QList<bool> flags;
    flags
        << index.data(Ready).toBool()
        << index.data(ServerAdmin).toBool()
        << index.data(RoomAdmin).toBool()
        << index.data(Registered).toBool()
        << index.data(Friend).toBool()
        << index.data(Ignore).toBool()
        ;

    for(int i = flags.size() - 1; i >= 0; --i)
        if(flags[i])
            iconNum |= 1 << i;

    if(m_icons().contains(iconNum))
    {
        setData(index, m_icons().value(iconNum), Qt::DecorationRole);
        qDebug("cached");
    }
    else
    {
        QPixmap result(24, 16);
        result.fill(Qt::transparent);

        QPainter painter(&result);

        if(index.data(Ready).toBool())
            painter.drawPixmap(0, 0, 16, 16, QPixmap(":/res/chat/lamp.png"));

        QString mainIconName(":/res/chat/");

        if(index.data(RoomAdmin).toBool())
            mainIconName += "roomadmin";
        else if(index.data(ServerAdmin).toBool())
            mainIconName += "serveradmin";
        else
            mainIconName += "hedgehog";

        if(!index.data(Registered).toBool())
            mainIconName += "_gray";

        painter.drawPixmap(8, 0, 16, 16, QPixmap(mainIconName + ".png"));

        if(index.data(Ignore).toBool())
            painter.drawPixmap(8, 0, 16, 16, QPixmap(":/res/chat/ignore.png"));
        else
        if(index.data(Friend).toBool())
            painter.drawPixmap(8, 0, 16, 16, QPixmap(":/res/chat/friend.png"));

        painter.end();

        QIcon icon(result);

        setData(index, icon, Qt::DecorationRole);
        m_icons().insert(iconNum, icon);
    }

    if(index.data(Ignore).toBool())
        setData(index, Qt::gray, Qt::ForegroundRole);
    else
    if(index.data(Friend).toBool())
        setData(index, Qt::green, Qt::ForegroundRole);
    else
        setData(index, QBrush(QColor(0xff, 0xcc, 0x00)), Qt::ForegroundRole);
}


QHash<quint32, QIcon> & PlayersListModel::m_icons()
{
    static QHash<quint32, QIcon> iconsCache;

    return iconsCache;
}
