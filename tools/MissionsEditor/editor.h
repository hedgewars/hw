#ifndef EDITOR_H
#define EDITOR_H

#include <QtGui/QMainWindow>

namespace Ui
{
    class editor;
}

class QCheckBox;

class editor : public QMainWindow
{
    Q_OBJECT

public:
    editor(QWidget *parent = 0);
    ~editor();

private:
    Ui::editor *ui;
    QList<QCheckBox  *> cbFlags;

    void load(const QString & fileName);

private slots:
    void on_actionLoad_triggered();
};

#endif // EDITOR_H
