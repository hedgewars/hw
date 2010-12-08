/*
 * Copyright (c) 2009 Nokia Corporation.
 */

#ifndef QASPECTRATIOLAYOUT_H_
#define QASPECTRATIOLAYOUT_H_

#include <QLayout>
#include <QPointer>
#include <QRect>
#include <QWidgetItem>
#include <QLayoutItem>


class QAspectRatioLayout : public QLayout
{
        Q_OBJECT

public:
        QAspectRatioLayout(QWidget* parent, int spacing =-1);
        QAspectRatioLayout(int spacing = -1);
        ~QAspectRatioLayout();

        /* Convenience method */
        virtual void add(QLayoutItem* item);

/* http://doc.trolltech.com/qlayout.html#addItem */
        virtual void addItem(QLayoutItem* item);
        /* http://doc.trolltech.com/qlayout.html#addWidget */
        virtual void addWidget(QWidget* widget);
        /* http://doc.trolltech.com/qlayout.html#takeAt */
        virtual QLayoutItem* takeAt(int index);
        /* http://doc.trolltech.com/qlayout.html#itemAt */
        virtual QLayoutItem* itemAt(int index) const;
        /* http://doc.trolltech.com/qlayout.html#count */
        virtual int count() const;

        /*
         * These are ours since we do have only one item.
         */
        virtual QLayoutItem* replaceItem(QLayoutItem* item);
        virtual QLayoutItem* take();
        virtual bool hasItem() const;

/* http://doc.trolltech.com/qlayout.html#expandingDirections */
        virtual Qt::Orientations expandingDirections() const;

        /*
         * This method contains most of the juice of this article.
         * http://doc.trolltech.com/qlayoutitem.html#setGeometry
         */
        virtual void setGeometry(const QRect& rect);
        /* http://doc.trolltech.com/qlayoutitem.html#geometry */
        virtual QRect geometry();

        /* http://doc.trolltech.com/qlayoutitem.html#sizeHint */
        virtual QSize sizeHint() const;
        /* http://doc.trolltech.com/qlayout.html#minimumSize */
        virtual QSize minimumSize() const;
        /* http://doc.trolltech.com/qlayoutitem.html#hasHeightForWidth */
        virtual bool hasHeightForWidth() const;

private:
        /* Saves the last received rect. */
        void setLastReceivedRect(const QRect& rect);
        /* Used to initialize the object. */
        void init(int spacing);
        /* Calculates the maximum size for the item from the assigned size. */
        QSize calculateProperSize(QSize from) const;
        /* Calculates the center location from the assigned size and
         * the items size. */
        QPoint calculateCenterLocation(QSize from, QSize itemSize) const;
        /* Check if two QRects are equal */
        bool areRectsEqual(const QRect& a, const QRect& b) const;
        /* Contains item reference */
        QLayoutItem* item;
        /*
         * Used for caching so we won't do calculations every time
         * setGeometry is called.
         */
        QRect* lastReceivedRect;
        /* Contains geometry */
        QRect* _geometry;

};

#endif /* QASPECTRATIOLAYOUT_H_ */
