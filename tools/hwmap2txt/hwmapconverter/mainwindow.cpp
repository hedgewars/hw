#include <QByteArray>
#include <QFile>
#include <QFileDialog>
#include <QtEndian>
#include <QRegExp>

#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_pbLoad_clicked()
{
    QString fileName = QFileDialog::getOpenFileName(this, QString(), QString(), "Hedgewars drawn maps (*.hwmap);;All files (*.*)");

    if(!fileName.isEmpty())
    {
        QFile f(fileName);

        if(f.open(QFile::ReadOnly))
        {
            QByteArray data = qUncompress(QByteArray::fromBase64(f.readAll()));

            QStringList decoded;

            bool isSpecial = true;
            while(data.size() >= 5)
            {
                qint16 px = qFromBigEndian(*(qint16 *)data.data());
                data.remove(0, 2);
                qint16 py = qFromBigEndian(*(qint16 *)data.data());
                data.remove(0, 2);
                quint8 flags = *(quint8 *)data.data();
                data.remove(0, 1);

                if(flags & 0x80)
                {
                    if(isSpecial && !decoded.isEmpty())
                        decoded << "// drawings";

                    isSpecial = false;

                    quint8 penWidth = flags & 0x3f;
                    bool isErasing = flags & 0x40;
                    decoded << QString("%1 %2 %3 %4")
                               .arg(px, 5).arg(py, 6)
                               .arg(isErasing ? "e" : "s")
                               .arg(penWidth, 2);
                } else
                    if(isSpecial)
                    {
                        if(decoded.isEmpty())
                            decoded << "// special points (these are always before all drawings!)";

                        decoded << QString("%1 %2 %3")
                                   .arg(px, 5).arg(py, 6)
                                   .arg(flags);
                    } else
                    {
                        decoded << QString("%1 %2")
                                   .arg(px, 5).arg(py, 6);
                    }
            }

            ui->textEdit->setPlainText(decoded.join("\n"));
            ui->statusBar->showMessage("Load OK");
        } else
            ui->statusBar->showMessage(QString("Can't open file %1").arg(fileName));
    }
}

void MainWindow::on_pbSave_clicked()
{
    QRegExp rxSP("^\\s*(-?\\d+)\\s*(-?\\d+)\\s*(\\d+)\\s*$");
    QRegExp rxLS("^\\s*(-?\\d+)\\s*(-?\\d+)\\s*([es])\\s*(\\d+)\\s*$");
    QRegExp rxP("^\\s*(-?\\d+)\\s*(-?\\d+)\\s*$");

    QString fileName = QFileDialog::getSaveFileName(this, QString(), QString(), "Hedgewars drawn maps (*.hwmap);;All files (*.*)");

    QFile file(fileName);
    if(file.open(QFile::WriteOnly))
    {
        QByteArray b;
        QStringList sl = ui->textEdit->toPlainText().split('\n');
        bool isSpecial = true;

        foreach(const QString & line, sl)
            if(!line.startsWith("//"))
            {
                if(rxLS.indexIn(line) != -1)
                {
                    isSpecial = false;
                    qint16 px = qToBigEndian((qint16)rxLS.cap(1).toInt());
                    qint16 py = qToBigEndian((qint16)rxLS.cap(2).toInt());
                    quint8 flags = 0x80;
                    if(rxLS.cap(3) == "e") flags |= 0x40;
                    flags = flags + rxLS.cap(4).toUInt();
                    b.append((const char *)&px, 2);
                    b.append((const char *)&py, 2);
                    b.append((const char *)&flags, 1);
                } else
                if(isSpecial && (rxSP.indexIn(line) != -1))
                {
                    qint16 px = qToBigEndian((qint16)rxSP.cap(1).toInt());
                    qint16 py = qToBigEndian((qint16)rxSP.cap(2).toInt());
                    quint8 flags = rxSP.cap(3).toUInt();

                    b.append((const char *)&px, 2);
                    b.append((const char *)&py, 2);
                    b.append((const char *)&flags, 1);
                } else
                if(rxP.indexIn(line) != -1)
                {
                    isSpecial = false;
                    qint16 px = qToBigEndian((qint16)rxP.cap(1).toInt());
                    qint16 py = qToBigEndian((qint16)rxP.cap(2).toInt());
                    quint8 flags = 0;
                    b.append((const char *)&px, 2);
                    b.append((const char *)&py, 2);
                    b.append((const char *)&flags, 1);
                } else
                    ui->statusBar->showMessage(QString("Can't parse or misplaced special point: %1").arg(line));
            }

        file.write(qCompress(b).toBase64());
    }
}
