/*
 * Copyright (c) 2009 Nokia Corporation.
 */

#include "qaspectratiolayout.h"

QAspectRatioLayout::QAspectRatioLayout(QWidget* parent, int spacing) : QLayout(parent) {
        init(spacing);
}

QAspectRatioLayout::QAspectRatioLayout(int spacing) {
        init(spacing);
}

QAspectRatioLayout::~QAspectRatioLayout() {
        delete item;
        delete lastReceivedRect;
        delete _geometry;
}

void QAspectRatioLayout::init(int spacing) {
        item = 0;
        lastReceivedRect = new QRect(0, 0, 0, 0);
        _geometry = new QRect(0, 0, 0, 0);
        setSpacing(spacing);
}


/* Adds item if place isn't already taken. */
void QAspectRatioLayout::add(QLayoutItem* item) {
        if(!hasItem()) {
                replaceItem(item);
        }
}

/* Adds item if place isn't already taken. */
void QAspectRatioLayout::addItem(QLayoutItem* item) {
        if(!hasItem()) {
                replaceItem(item);
        }
}

/* Adds widget if place isn't already taken. */
void QAspectRatioLayout::addWidget(QWidget* widget) {
        if(!hasItem()) {
                replaceItem(new QWidgetItem(widget));
        }
}

/* Returns the item pointer and dereferences it here. */
QLayoutItem* QAspectRatioLayout::take() {
        QLayoutItem* item = 0;
        if(this->hasItem()) {
                item = this->item;
                this->item = 0;
        }
        return item;
}

/* Returns the item pointer and dereferences it here. */
QLayoutItem* QAspectRatioLayout::takeAt(int index) {
        if(index != 0) {
                return 0;
        }
        return this->take();
}

/* Returns the item pointer. */
QLayoutItem* QAspectRatioLayout::itemAt(int index) const {
        if(index != 0) {
                return 0;
        }
        if(hasItem()) {
                return this->item;
        }
        return 0;
}

/* Checks if we have an item. */
bool QAspectRatioLayout::hasItem() const {
        return this->item != 0;
}

/* Returns the count of items which can be either 0 or 1. */
int QAspectRatioLayout::count() const {
        int returnValue = 0;
        if(hasItem()) {
                returnValue = 1;
        }
        return returnValue;
}

/* Replaces the item with the new and returns the old. */
QLayoutItem* QAspectRatioLayout::replaceItem(QLayoutItem* item) {
        QLayoutItem* old = 0;
        if(this->hasItem()) {
                old = this->item;
        }
        this->item = item;
        setGeometry(*this->_geometry);
        return old;
}

/* Tells which way layout expands. */
Qt::Orientations QAspectRatioLayout::expandingDirections() const {
        return Qt::Horizontal | Qt::Vertical;
}

/* Tells which size is preferred. */
QSize QAspectRatioLayout::sizeHint() const {
        return this->item->minimumSize();
}

/* Tells minimum size. */
QSize QAspectRatioLayout::minimumSize() const {
        return this->item->minimumSize();
}

/*
 * Tells if heightForWidth calculations is handled.
 * It isn't since width isn't enough to calculate
 * proper size.
 */
bool QAspectRatioLayout::hasHeightForWidth() const {
        return false;
}

/* Replaces lastReceivedRect. */
void QAspectRatioLayout::setLastReceivedRect(const QRect& rect) {
        QRect* oldRect = this->lastReceivedRect;
        this->lastReceivedRect = new QRect(rect.topLeft(), rect.size());
        delete oldRect;
}

/* Returns geometry */
QRect QAspectRatioLayout::geometry() {
        return QRect(*this->_geometry);
}

/* Sets geometry to given size. */
void QAspectRatioLayout::setGeometry(const QRect& rect) {
        /*
         * We check if the item is set and
         * if size is the same previously received.
         * If either is false nothing is done.
         */
        if(!this->hasItem() ||
           areRectsEqual(*this->lastReceivedRect, rect)) {
                return;
        }
        /* Replace the last received rectangle. */
        setLastReceivedRect(rect);
        /* Calculate proper size for the item relative to the received size. */
        QSize properSize = calculateProperSize(rect.size());
        /* Calculate center location in the rect and with item size. */
        QPoint properLocation = calculateCenterLocation(rect.size(), properSize);
        /* Set items geometry */
        this->item->setGeometry(QRect(properLocation, properSize));
        QRect* oldRect = this->_geometry;
        /* Cache the calculated geometry. */
        this->_geometry = new QRect(properLocation, properSize);
        delete oldRect;
        /* Super classes setGeometry */
        QLayout::setGeometry(*this->_geometry);
}

/* Takes the shortest side and creates QSize
 * with the shortest side as width and height. */
QSize QAspectRatioLayout::calculateProperSize(QSize from) const {
        QSize properSize;
        if(from.height() * 2 < from.width()) {
                properSize.setHeight(from.height() - this->margin());
                properSize.setWidth(from.height() * 2 - this->margin());
        }
        else {
                properSize.setWidth(from.width() - this->margin());
                properSize.setHeight(from.width() / 2 - this->margin());
        }
        return properSize;
}

/* Calculates center location from the given height and width for item size. */
QPoint QAspectRatioLayout::calculateCenterLocation(QSize from,
                                                   QSize itemSize) const {
        QPoint centerLocation;
        if((from.width() - itemSize.width()) > 0) {
                centerLocation.setX((from.width() - itemSize.width())/2);
        }
        if((from.height() - itemSize.height()) > 0) {
                centerLocation.setY((from.height() - itemSize.height())/2);
        }
        return centerLocation;
}

/* Compares if two QRects are equal. */
bool QAspectRatioLayout::areRectsEqual(const QRect& a,
                                       const QRect& b) const {
        bool result = false;
        if(a.x() == b.x() &&
           a.y() == b.y() &&
           a.height() == b.height() &&
           a.width() == b.width()) {
                result = true;
        }
        return result;
}
