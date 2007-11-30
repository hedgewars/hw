#include "weaponItem.h"

WeaponItem::WeaponItem(const QImage& im, QWidget * parent) :
  ItemNum(im, parent)
{
}

WeaponItem::~WeaponItem()
{
}

void WeaponItem::incItems()
{
  ++numItems;
}

void WeaponItem::decItems()
{
  --numItems;
}

