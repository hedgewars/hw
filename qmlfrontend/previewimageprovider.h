#ifndef PREVIEWIMAGEPROVIDER_H
#define PREVIEWIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QPixmap>
#include <QSize>

class PreviewImageProvider : public QQuickImageProvider
{
public:
    PreviewImageProvider();

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize);

    void setPixmap(const QByteArray & px);

private:
    QPixmap m_px;
};

#endif // PREVIEWIMAGEPROVIDER_H
