#ifndef PLAYERSLISTMODEL_H
#define PLAYERSLISTMODEL_H

#include <QAbstractListModel>
#include <QHash>
#include <QIcon>
#include <QModelIndex>
#include <QSet>
#include <QFont>

class PlayersListModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum StateFlag {
        Ready       = Qt::UserRole,
        ServerAdmin = Qt::UserRole + 1,
        RoomAdmin   = Qt::UserRole + 2,
        Registered  = Qt::UserRole + 3,
        Friend      = Qt::UserRole + 4,
        Ignore      = Qt::UserRole + 5,
        InGame      = Qt::UserRole + 6,
        InRoom      = Qt::UserRole + 7,
        Contributor = Qt::UserRole + 8
        // if you add a role that will affect the player icon,
        // then also add it to the flags Qlist in updateIcon()!
    };

    enum SpecialRoles {
        SortRole       = Qt::UserRole + 100,
        RoomFilterRole = Qt::UserRole + 101
    };

    explicit PlayersListModel(QObject *parent = 0);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;

    QVariant data(const QModelIndex &index, int role) const;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::DisplayRole);
    void setFlag(const QString & nickname, StateFlag flagType, bool isSet);
    bool isFlagSet(const QString & nickname, StateFlag flagType);

    bool insertRow(int row, const QModelIndex &parent = QModelIndex());
    bool insertRows(int row, int count, const QModelIndex &parent = QModelIndex());
    bool removeRows(int row, int count, const QModelIndex &parent = QModelIndex());

    QModelIndex nicknameIndex(const QString & nickname);

public slots:
    void addPlayer(const QString & nickname, bool notify);
    void removePlayer(const QString & nickname, const QString & msg = QString());
    void playerJoinedRoom(const QString & nickname, bool notify);
    void playerLeftRoom(const QString & nickname);
    void resetRoomFlags();
    void setNickname(const QString & nickname);

signals:
    void nickAdded(const QString& nick, bool notifyNick);
    void nickRemoved(const QString& nick);
    void nickAddedLobby(const QString& nick, bool notifyNick);
    void nickRemovedLobby(const QString& nick);
    void nickRemovedLobby(const QString& nick, const QString& message);

private:
    QHash<quint32, QIcon> & m_icons();
    typedef QHash<int, QVariant> DataEntry;
    QList<DataEntry> m_data;
    QSet<QString> m_friendsSet, m_ignoredSet;
    QString m_nickname;
    QFont m_fontInRoom;

    void updateIcon(const QModelIndex & index);
    void updateSortData(const QModelIndex & index);
    void loadSet(QSet<QString> & set, const QString & suffix);
    void saveSet(const QSet<QString> & set, const QString & suffix);
    void checkFriendIgnore(const QModelIndex & mi);
    bool isFriend(const QString & nickname);
    bool isIgnored(const QString & nickname);
};

#endif // PLAYERSLISTMODEL_H
