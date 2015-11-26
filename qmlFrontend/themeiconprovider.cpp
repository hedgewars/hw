#include <QByteArray>
#include <QDebug>

#include "themeiconprovider.h"
#include "flib.h"

ThemeIconProvider::ThemeIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
    getThemeIcon = 0;
}

void ThemeIconProvider::setFileContentsFunction(getThemeIcon_t *f)
{
    getThemeIcon = f;
}

QImage ThemeIconProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize);

    if(!getThemeIcon)
        return QImage();

    QByteArray buf;
    buf.resize(65536);

    char * bufptr = buf.data();
    uint32_t fileSize = getThemeIcon(id.toUtf8().data(), bufptr, buf.size());
    buf.truncate(fileSize);
    //qDebug() << "ThemeIconProvider file size = " << fileSize;

    QImage img = fileSize ? QImage::fromData(buf) : QImage(16, 16, QImage::Format_ARGB32);

    if (size)
        *size = img.size();
    return img;
}
