#include "roomslistmodel.h"

RoomsListModel::RoomsListModel(QObject *parent) :
    QAbstractTableModel(parent)
{
    m_headerData =
    QStringList()
     << tr("Room Name")
     << tr("C")
     << tr("T")
     << tr("Owner")
     << tr("Map")
     << tr("Rules")
     << tr("Weapons");
}

QVariant RoomsListModel::headerData(int section, Qt::Orientation orientation, int role) const
{
    if(orientation == Qt::Vertical || role != Qt::DisplayRole)
        return QVariant();
    else
        return QVariant(m_headerData.at(section));
}

int RoomsListModel::rowCount(const QModelIndex & parent) const
{
    if(parent.isValid())
        return 0;
    else
        return m_data.size();
}

int RoomsListModel::columnCount(const QModelIndex & parent) const
{
    if(parent.isValid())
        return 0;
    else
        return 7;
}

QVariant RoomsListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0
            || index.row() >= m_data.size()
            || index.column() >= 7
            || (role != Qt::EditRole && role != Qt::DisplayRole)
       )
        return QVariant();

    return m_data.at(index.row()).at(index.column());
}
