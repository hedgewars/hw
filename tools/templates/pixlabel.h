#include <QLabel>
#include <QRect>
#include <QList>
#include <QMouseEvent>

class PixLabel : public QLabel
{
    Q_OBJECT

public:

    PixLabel();
    QList<QRect> rects;

public slots:
    void AddRect();

private:
    void paintEvent(QPaintEvent * event);
    void mousePressEvent(QMouseEvent * e);
};
