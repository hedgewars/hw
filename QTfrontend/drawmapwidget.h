#ifndef DRAWMAPWIDGET_H
#define DRAWMAPWIDGET_H

#include <QWidget>
#include <QHBoxLayout>
#include <QPushButton>
#include <QGraphicsView>
#include <QApplication>

#include "qaspectratiolayout.h"
#include "drawmapscene.h"

namespace Ui {
    class Ui_DrawMapWidget
    {
    public:
        QGraphicsView *graphicsView;

        void setupUi(QWidget *drawMapWidget)
        {
            QAspectRatioLayout * arLayout = new QAspectRatioLayout(drawMapWidget);
            arLayout->setMargin(0);

            graphicsView = new QGraphicsView(drawMapWidget);
            arLayout->addWidget(graphicsView);

            retranslateUi(drawMapWidget);

            QMetaObject::connectSlotsByName(drawMapWidget);
        } // setupUi

        void retranslateUi(QWidget *drawMapWidget)
        {
            Q_UNUSED(drawMapWidget);
        } // retranslateUi

    };

    class DrawMapWidget: public Ui_DrawMapWidget {};
}

class DrawMapWidget : public QWidget
{
    Q_OBJECT

public:
    explicit DrawMapWidget(QWidget *parent = 0);
    ~DrawMapWidget();

    void setScene(DrawMapScene * scene);

public slots:
    void undo();
    void clear();
    void save(const QString & fileName);
    void load(const QString & fileName);

protected:
    void changeEvent(QEvent *e);
    virtual void resizeEvent(QResizeEvent * event);
    virtual void showEvent(QShowEvent * event);

private:
    Ui::DrawMapWidget *ui;

    DrawMapScene * m_scene;
};

#endif // DRAWMAPWIDGET_H
