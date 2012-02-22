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

private:
    QList<QStringList> m_data;
    QStringList m_headerData;
};

#endif // ROOMSLISTMODEL_H
