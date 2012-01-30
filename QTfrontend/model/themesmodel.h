#ifndef THEMESMODEL_H
#define THEMESMODEL_H

#include <QAbstractListModel>
#include <QStringList>
#include <QHash>

class ThemesModel : public QAbstractListModel
{
        Q_OBJECT
    public:
        explicit ThemesModel(QStringList themes, QObject *parent = 0);

        int rowCount(const QModelIndex &parent = QModelIndex()) const;
        QVariant data(const QModelIndex &index, int role) const;
        bool setData(const QModelIndex &index, const QVariant &value,
                     int role = Qt::EditRole);

    signals:

    public slots:

    private:

        QList<QHash<int, QVariant> > m_data;
};

#endif // THEMESMODEL_H
