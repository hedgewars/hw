#ifndef THEMEICONPROVIDER_H
#define THEMEICONPROVIDER_H

#include <QQuickImageProvider>
#include <QImage>

#include "flib.h"

class ThemeIconProvider : public QQuickImageProvider
{
public:
    ThemeIconProvider();

    void setFileContentsFunction(getThemeIcon_t *f);

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);
private:
    getThemeIcon_t *getThemeIcon;
};

#endif // THEMEICONPROVIDER_H
