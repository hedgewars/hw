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

    virtual void resizeEvent(QResizeEvent * event);

private slots:
    void on_pbSimplify_clicked();
    void scene_pathChanged();
};

#endif // MAINWINDOW_H
