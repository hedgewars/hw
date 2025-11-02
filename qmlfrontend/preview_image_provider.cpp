#include "preview_image_provider.h"

PreviewImageProvider::PreviewImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

QPixmap PreviewImageProvider::requestPixmap(const QString &id, QSize *size,
                                            const QSize &requestedSize) {
  Q_UNUSED(id);
  Q_UNUSED(requestedSize);

  if (size) *size = m_px.size();

  return m_px;
}

void PreviewImageProvider::setImage(const QImage &preview) {
  m_px = QPixmap::fromImage(preview, Qt::ColorOnly);
  // QPixmap pxres(px.size());
  // QPainter p(&pxres);

  // p.fillRect(pxres.rect(), linearGrad);
  // p.drawPixmap(0, 0, px);
}
