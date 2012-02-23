#ifndef ROOMSLISTMODEL_H
#define ROOMSLISTMODEL_H

#include <QAbstractTableModel>
#include <QStringList>

class RoomsListModel : public QAbstractTableModel
{
    Q_OBJECT
public:
    explicit RoomsListModel(QObject *parent = 0);

    QVariant headerData(int section, Qt::Orientation orientation, int role) const;
    int rowCount(const QModelIndex & parent) const;
    int columnCount(const QModelIndex & parent) const;
    QVariant data(const QModelIndex &index, int role) const;

public slots:
    void setRoomsList(const QStringList & rooms);
    void addRoom(const QStringList & info);
    void removeRoom(const QString & name);
    void updateRoom(const QString & name, const QStringList & info);

private:
    QList<QStringList> m_data;
    QStringList m_headerData;

    QStringList roomInfo2RoomRecord(const QStringList & info);
};

#endif // ROOMSLISTMODEL_H
