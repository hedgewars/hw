#ifndef PLAYERSLISTMODEL_H
#define PLAYERSLISTMODEL_H

#include <QAbstractListModel>
#include <QHash>
#include <QIcon>
#include <QModelIndex>

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
        Ignore      = Qt::UserRole + 5
    };

    enum SpecialRoles {
        SortRole = Qt::UserRole + 100
    };

    explicit PlayersListModel(QObject *parent = 0);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;

    QVariant data(const QModelIndex &index, int role) const;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::DisplayRole);

    bool insertRow(int row, const QModelIndex &parent = QModelIndex());
    bool insertRows(int row, int count, const QModelIndex &parent = QModelIndex());
    bool removeRows(int row, int count, const QModelIndex &parent = QModelIndex());

public slots:
    void addPlayer(const QString & nickname);
    void removePlayer(const QString & nickname);
    void setFlag(const QString & nickname, StateFlag flagType, bool isSet);

private:
    QHash<quint32, QIcon> & m_icons();
    typedef QHash<int, QVariant> DataEntry;
    QList<DataEntry> m_data;
    void updateIcon(const QModelIndex & index);
    void updateSortData(const QModelIndex & index);
};

#endif // PLAYERSLISTMODEL_H
