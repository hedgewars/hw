#include <QFileDialog>

#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "drawmapscene.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    scene = new DrawMapScene(this);
    //ui->graphicsView->setScene(scene);
    ui->drawMapWidget->setScene(scene);

    connect(ui->pbUndo, SIGNAL(clicked()), scene, SLOT(undo()));
    connect(scene, SIGNAL(pathChanged()), this, SLOT(scene_pathChanged()));
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::changeEvent(QEvent *e)
{
    QMainWindow::changeEvent(e);
    switch (e->type()) {
    case QEvent::LanguageChange:
        ui->retranslateUi(this);
        break;
    default:
        break;
    }
}

void MainWindow::scene_pathChanged()
{
    QString str = scene->encode().toBase64();
    ui->plainTextEdit->setPlainText(str);
    ui->sbBytes->setValue(str.size());
}

void MainWindow::on_pbSave_clicked()
{
    QString fileName = QFileDialog::getSaveFileName(this, tr("Save map"), ".");

    if(!fileName.isEmpty())
    {
        QFile f(fileName);

        f.open(QIODevice::WriteOnly);
        f.write(scene->encode());
    }
}

void MainWindow::on_pbLoad_clicked()
{
    QString fileName = QFileDialog::getOpenFileName(this, tr("Open map file"), ".");

    if(!fileName.isEmpty())
    {
        QFile f(fileName);

        f.open(QIODevice::ReadOnly);
        QByteArray data = f.readAll();
        scene->decode(data);
    }
}
