#include <QPainter>
#include <QPen>
#include "pixlabel.h"

PixLabel::PixLabel()
		: QLabel(0)
{

}

void PixLabel::paintEvent(QPaintEvent * event)
{
	QLabel::paintEvent(event);
	QPainter p(this);

	p.fillRect(QRect(0, 0, 1024, 512), QBrush(Qt::black));

	if (rects.size())
	{
		p.setPen(QPen(Qt::lightGray));
		QVector<QPoint> centers;
		for(QList<QRect>::const_iterator it = rects.begin(); it != rects.end(); ++it)
			centers.push_back((*it).center());
		p.drawPolyline(QPolygon(centers));

		p.setPen(QPen(Qt::white));
		p.drawRects(rects.toVector());

		p.setPen(QPen(Qt::yellow));
		p.drawRect(rects.last());
	}
}

void PixLabel::mousePressEvent(QMouseEvent * e)
{
	if (!rects.empty())
	{
		if (e->button() == Qt::LeftButton)
			rects[rects.size() - 1].moveTopLeft(QPoint(e->x(), e->y()));
		else
		if (e->button() == Qt::RightButton)
			rects[rects.size() - 1].setBottomRight(QPoint(e->x(), e->y()));
		repaint();
	}
}

void PixLabel::AddRect()
{
	rects.push_back(QRect(0, 0, 1, 1));
	repaint();
}
