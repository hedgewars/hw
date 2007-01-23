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

	p.setPen(QPen(Qt::white));
	p.drawRects(rects.toVector());

	if (rects.size())
	{
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
