#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>

namespace Ui {
    class MainWindow;
}

class DrawMapScene;

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

protected:
    void changeEvent(QEvent *e);

private:
    Ui::MainWindow *ui;
    DrawMapScene * scene;

private slots:
    void on_pbLoad_clicked();
    void on_pbSave_clicked();
    void scene_pathChanged();
};

#endif // MAINWINDOW_H
