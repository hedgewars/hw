#include <QFile>
#include <QMessageBox>

#include "drawmapwidget.h"

DrawMapWidget::DrawMapWidget(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::DrawMapWidget)
{
    ui->setupUi(this);

    m_scene = 0;
}

DrawMapWidget::~DrawMapWidget()
{
    delete ui;
}

void DrawMapWidget::changeEvent(QEvent *e)
{
    QWidget::changeEvent(e);
    switch (e->type()) {
    case QEvent::LanguageChange:
        ui->retranslateUi(this);
        break;
    default:
        break;
    }
}

void DrawMapWidget::setScene(DrawMapScene * scene)
{
    ui->graphicsView->setScene(scene);
    m_scene = scene;
}

void DrawMapWidget::resizeEvent(QResizeEvent * event)
{
    Q_UNUSED(event);

    if(ui->graphicsView && ui->graphicsView->scene())
        ui->graphicsView->fitInView(ui->graphicsView->scene()->sceneRect(), Qt::KeepAspectRatio);
}

void DrawMapWidget::showEvent(QShowEvent * event)
{
    Q_UNUSED(event);

    resizeEvent(0);
}

void DrawMapWidget::undo()
{
    if(m_scene) m_scene->undo();
}

void DrawMapWidget::clear()
{
    if(m_scene) m_scene->clearMap();
}

void DrawMapWidget::save(const QString & fileName)
{
    if(m_scene)
    {
        QFile file(fileName);

        if(!file.open(QIODevice::WriteOnly))
            QMessageBox::warning(this, tr("File error"), tr("Cannot open file '%1' for writing").arg(fileName));
        else
            file.write(qCompress(m_scene->encode()).toBase64());
    }
}

void DrawMapWidget::load(const QString & fileName)
{
    if(m_scene)
    {
        QFile f(fileName);

        if(!f.open(QIODevice::ReadOnly))
            QMessageBox::warning(this, tr("File error"), tr("Cannot read file '%1'").arg(fileName));
        else
            m_scene->decode(qUncompress(QByteArray::fromBase64(f.readAll())));
    }
}
