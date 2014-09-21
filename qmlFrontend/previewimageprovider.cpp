#include "previewimageprovider.h"

PreviewImageProvider::PreviewImageProvider()
        : QQuickImageProvider(QQuickImageProvider::Pixmap)
{
}

QPixmap PreviewImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id);
    Q_UNUSED(requestedSize);

    if (size)
        *size = m_px.size();

    return m_px;
}

void PreviewImageProvider::setPixmap(const QPixmap & px)
{
    m_px = px;
}
