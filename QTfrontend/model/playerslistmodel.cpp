#include <QModelIndexList>
#include <QModelIndex>
#include <QPainter>
#include <QFile>
#include <QTextStream>
#include <QDebug>

#include "playerslistmodel.h"
#include "hwconsts.h"

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
    if(!index.isValid() || index.row() < 0 || index.row() >= rowCount() || index.column() != 0)
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

    QModelIndex mi = index(rowCount() - 1);
    setData(mi, nickname);

    checkFriendIgnore(mi);
}


void PlayersListModel::removePlayer(const QString & nickname)
{
    QModelIndexList mil = match(index(0), Qt::DisplayRole, nickname);

    if(mil.size())
        removeRow(mil[0].row());
}


void PlayersListModel::playerJoinedRoom(const QString & nickname)
{
    QModelIndexList mil = match(index(0), Qt::DisplayRole, nickname);

    if(mil.size())
        setData(mil[0], "1", RoomFilterRole);
}


void PlayersListModel::playerLeftRoom(const QString & nickname)
{
    QModelIndexList mil = match(index(0), Qt::DisplayRole, nickname);

    if(mil.size())
        setData(mil[0], "0", RoomFilterRole);
}


void PlayersListModel::setFlag(const QString &nickname, StateFlag flagType, bool isSet)
{
    QModelIndexList mil = match(index(0), Qt::DisplayRole, nickname);

    if(mil.size())
    {
        setData(mil[0], isSet, flagType);

        if(flagType == Friend || flagType == ServerAdmin
                || flagType == Ignore || flagType == RoomAdmin)
            updateSortData(mil[0]);

        if(flagType == Friend)
        {
            if(isSet)
                m_friendsSet.insert(nickname.toLower());
            else
                m_friendsSet.remove(nickname.toLower());

            saveSet(m_friendsSet, "friends");
        }

        if(flagType == Ignore)
        {
            if(isSet)
                m_ignoredSet.insert(nickname.toLower());
            else
                m_ignoredSet.remove(nickname.toLower());

            saveSet(m_ignoredSet, "ignore");
        }

        updateIcon(mil[0]);
    }
}


bool PlayersListModel::isFlagSet(const QString & nickname, StateFlag flagType)
{
    QModelIndexList mil = match(index(0), Qt::DisplayRole, nickname);

    if(mil.size())
        return mil[0].data(flagType).toBool();
    else
        return false;
}

void PlayersListModel::resetRoomFlags()
{
    for(int i = rowCount() - 1; i >= 0; --i)
    {
        QModelIndex mi = index(i);

        if(mi.data(RoomFilterRole).toString() == "1")
        {
            setData(mi, "0", RoomFilterRole);
            setData(mi, false, RoomAdmin);
            setData(mi, false, Ready);

            updateSortData(mi);
            updateIcon(mi);
        }
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


void PlayersListModel::updateSortData(const QModelIndex & index)
{
    QString result = QString("%1%2%3%4%5%6")
            // room admins go first, then server admins, then friends
            .arg(1 - index.data(RoomAdmin).toInt())
            .arg(1 - index.data(ServerAdmin).toInt())
            .arg(1 - index.data(Friend).toInt())
            // ignored at bottom
            .arg(index.data(Ignore).toInt())
            // keep nicknames starting from non-letter character at bottom within group
            // assume there are no empty nicks in list
            .arg(index.data(Qt::DisplayRole).toString().at(0).isLetter() ? 0 : 1)
            // sort ignoring case
            .arg(index.data(Qt::DisplayRole).toString().toLower())
            ;

    setData(index, result, SortRole);
}


void PlayersListModel::setNickname(const QString &nickname)
{
    m_nickname = nickname;

    loadSet(m_friendsSet, "friends");
    loadSet(m_ignoredSet, "ignore");

    for(int i = rowCount() - 1; i >= 0; --i)
        checkFriendIgnore(index(i));
}


void PlayersListModel::checkFriendIgnore(const QModelIndex &mi)
{
    setData(mi, m_friendsSet.contains(mi.data().toString().toLower()), Friend);
    setData(mi, m_ignoredSet.contains(mi.data().toString().toLower()), Ignore);

    updateIcon(mi);
    updateSortData(mi);
}

void PlayersListModel::loadSet(QSet<QString> & set, const QString & suffix)
{
    set.clear();

    QString fileName = QString("%1/%2_%3.txt").arg(cfgdir->absolutePath(), m_nickname.toLower(), suffix);

    QFile txt(fileName);
    if(!txt.open(QIODevice::ReadOnly))
        return;

    QTextStream stream(&txt);
    stream.setCodec("UTF-8");

    while(!stream.atEnd())
    {
        QString str = stream.readLine();
        if(str.startsWith(";") || str.isEmpty())
            continue;

        set.insert(str.trimmed());
    }

    txt.close();
}

void PlayersListModel::saveSet(const QSet<QString> & set, const QString & suffix)
{
    qDebug("saving set");

    QString fileName = QString("%1/%2_%3.txt").arg(cfgdir->absolutePath(), m_nickname.toLower(), suffix);

    QFile txt(fileName);

    // list empty? => rather have no file for the list than an empty one
    if (set.isEmpty())
    {
        if (txt.exists())
        {
            // try to remove file, if successful we're done here.
            if (txt.remove())
                return;
        }
        else
            // there is no file
            return;
    }

    if(!txt.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;

    QTextStream stream(&txt);
    stream.setCodec("UTF-8");

    stream << "; this list is used by Hedgewars - do not edit it unless you know what you're doing!" << endl;

    foreach(const QString & nick, set.values())
        stream << nick << endl;

    txt.close();
}
