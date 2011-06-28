
#include "themesmodel.h"

ThemesModel::ThemesModel(QStringList themes, QObject *parent) :
    QAbstractListModel(parent)
{
#if QT_VERSION >= QT_VERSION_CHECK(4, 7, 0)
    m_data.reserve(themes.size());
#endif

    foreach(QString theme, themes)
    {
        m_data.append(QHash<int, QVariant>());
        m_data.last().insert(Qt::DisplayRole, theme);
    }
}

int ThemesModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    else
        return m_data.size();
}

QVariant ThemesModel::data(const QModelIndex &index, int role) const
{
    if(index.column() > 0 || index.row() >= m_data.size())
        return QVariant();
    else
        return m_data.at(index.row()).value(role);
}

bool ThemesModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if(index.column() > 0 || index.row() >= m_data.size())
        return false;
    else
    {
        m_data[index.row()].insert(role, value);

        return true;
    }

}




