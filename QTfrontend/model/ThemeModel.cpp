
#include "ThemeModel.h"

ThemeModel::ThemeModel(QObject *parent) :
    QAbstractListModel(parent)
{
    m_data = QList<QMap<int, QVariant> >();
}

int ThemeModel::rowCount(const QModelIndex &parent) const
{
    if(parent.isValid())
        return 0;
    else
        return m_data.size();
}


QVariant ThemeModel::data(const QModelIndex &index, int role) const
{
    if(index.column() > 0 || index.row() >= m_data.size())
        return QVariant();
    else
        return m_data.at(index.row()).value(role);
}


void ThemeModel::loadThemes()
{
    beginResetModel();


    DataManager & datamgr = DataManager::instance();

    QStringList themes =
        datamgr.entryList("Themes", QDir::AllDirs | QDir::NoDotAndDotDot);

    m_data.clear();

#if QT_VERSION >= QT_VERSION_CHECK(4, 7, 0)
    m_data.reserve(themes.size());
#endif

    foreach (QString theme, themes)
    {
        // themes without icon are supposed to be hidden
        QString iconpath =
            datamgr.findFileForRead(QString("Themes/%1/icon.png").arg(theme));

        if (!QFile::exists(iconpath))
            continue;

        QMap<int, QVariant> dataset;

        // set name
        dataset.insert(Qt::DisplayRole, theme);

        // load and set icon
        QIcon icon(iconpath);
        dataset.insert(Qt::DecorationRole, icon);

        // load and set preview icon
        QIcon preview(datamgr.findFileForRead(QString("Themes/%1/icon@2x.png").arg(theme)));
        dataset.insert(Qt::UserRole, preview);

        m_data.append(dataset);
    }


    endResetModel();
}




